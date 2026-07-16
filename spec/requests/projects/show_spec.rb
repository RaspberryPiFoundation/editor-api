# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project show requests' do
  let(:headers) { {} }
  let(:teacher) { create(:teacher, school:) }
  let(:authenticated_user) { teacher }
  let(:school) { create(:school) }

  context 'when user is logged in' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    before do
      authenticated_in_hydra_as(authenticated_user)
      stub_profile_api_list_school_students(school:, student_attributes: [{ name: 'Joe Bloggs' }])
      stub_profile_api_create_safeguarding_flag
    end

    context 'when loading own project' do
      let!(:project) { create(:project, :with_instructions, school:, user_id: teacher.id, locale: nil) }
      let(:project_json) do
        {
          identifier: project.identifier,
          project_type: Project::Types::PYTHON,
          locale: project.locale,
          name: project.name,
          user_id: project.user_id,
          instructions: project.instructions,
          components: [],
          image_list: [],
          videos: [],
          audio: []
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'returns the project json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.body).to eq(project_json)
      end

      it 'does not include the finished boolean in the project json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.parsed_body).not_to have_key('finished')
      end
    end

    context 'when loading a student\'s project' do
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
      let(:teacher_project) { create(:project, :with_instructions, school_id: school.id, lesson_id: lesson.id, user_id: teacher.id, locale: nil) }
      let(:student) { create(:student, school:) }
      let(:class_student) { create(:class_student, school_class:, student_id: student.id) }
      let(:student_project) do
        class_student
        create(:project, school_id: school.id, lesson_id: nil, user_id: student.id, remixed_from_id: teacher_project.id, locale: nil, instructions: teacher_project.instructions)
      end
      let(:student_project_json) do
        {
          identifier: student_project.identifier,
          project_type: Project::Types::PYTHON,
          locale: student_project.locale,
          name: student_project.name,
          user_id: student_project.user_id,
          instructions: student_project.instructions,
          parent: {
            name: teacher_project.name,
            identifier: teacher_project.identifier
          },
          components: [],
          image_list: [],
          videos: [],
          audio: [],
          user_name: 'Joe Bloggs'
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{student_project.identifier}", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'includes the expected parameters in the project json' do
        get("/api/projects/#{student_project.identifier}", headers:)
        expect(response.body).to eq(student_project_json)
      end

      it 'records a project opened event' do
        get("/api/projects/#{student_project.identifier}", headers:)

        expect(Event.last).to have_attributes(
          name: 'Project - Opened',
          user_id: teacher.id,
          properties: {
            'school_id' => school.id,
            'class_id' => school_class.id,
            'lesson_id' => lesson.id,
            'project_type' => Project::Types::PYTHON,
            'user_role' => 'educator',
            'student_id' => student.id
          },
          time: be_within(1.second).of(Time.current)
        )
      end
    end

    context 'when loading another teacher\'s project in a class where user is a teacher' do
      before do
        stub_user_info_api_for_users([teacher.id, another_teacher.id], users: [teacher, another_teacher])
      end

      let(:another_teacher) { create(:teacher, school:) }
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id, another_teacher.id]) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: another_teacher.id, visibility: 'teachers') }
      let(:another_teacher_project) { create(:project, :with_instructions, school:, lesson:, user_id: another_teacher.id, locale: nil) }
      let(:another_teacher_project_json) do
        {
          identifier: another_teacher_project.identifier,
          project_type: Project::Types::PYTHON,
          locale: another_teacher_project.locale,
          name: another_teacher_project.name,
          user_id: teacher.id,
          instructions: another_teacher_project.instructions,
          components: [],
          image_list: [],
          videos: [],
          audio: []
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{another_teacher_project.identifier}", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns the project json' do
        get("/api/projects/#{another_teacher_project.identifier}", headers:)
        expect(response.body).to eq(another_teacher_project_json)
      end
    end

    context "when a school owner loads another teacher's project outside their class" do
      let(:authenticated_user) { owner }
      let(:owner) { create(:owner, school:) }
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'teachers') }
      let(:project) { create(:project, school:, lesson:, user_id: teacher.id, locale: nil) }

      it 'returns the owner as the effective project owner without changing the stored owner' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['user_id']).to eq(owner.id)
        expect(project.reload.user_id).to eq(teacher.id)
      end
    end

    context "when a school owner loads a student's project from a class they teach" do
      let(:authenticated_user) { owner }
      let(:owner) { create(:owner, school:) }
      let(:student) { create(:student, school:) }
      let(:school_class) { create(:school_class, school:, teacher_ids: [owner.id]) }
      let(:class_student) { create(:class_student, school_class:, student_id: student.id) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: owner.id, visibility: 'students') }
      let(:lesson_project) { create(:project, school:, lesson:, user_id: owner.id, locale: nil) }
      let(:student_project) do
        class_student
        create(:project, school:, user_id: student.id, remixed_from_id: lesson_project.id, locale: nil)
      end

      before do
        create(:teacher_role, school:, user_id: owner.id)
      end

      it 'returns the student as the project owner because the school owner cannot update it' do
        get("/api/projects/#{student_project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['user_id']).to eq(student.id)
        expect(Ability.new(owner).can?(:update, student_project)).to be(false)
      end
    end

    context 'when loading another user\'s project' do
      let!(:another_project) { create(:project, user_id: SecureRandom.uuid, locale: nil) }
      let(:another_project_json) do
        {
          identifier: another_project.identifier,
          project_type: Project::Types::PYTHON,
          name: another_project.name,
          locale: another_project.locale,
          user_id: another_project.user_id,
          components: [],
          image_list: [],
          videos: [],
          audio: []
        }.to_json
      end

      it 'returns forbidden response' do
        get("/api/projects/#{another_project.identifier}", headers:)

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not return the project json' do
        get("/api/projects/#{another_project.identifier}", headers:)
        expect(response.body).not_to include(another_project_json)
      end
    end
  end

  context 'when user is not logged in' do
    context 'when loading a starter project' do
      let(:project_type) { Project::Types::PYTHON }
      let!(:starter_project) { create(:project, user_id: nil, locale: 'ja-JP', project_type:) }
      let(:starter_project_json) do
        {
          identifier: starter_project.identifier,
          project_type:,
          locale: starter_project.locale,
          name: starter_project.name,
          user_id: starter_project.user_id,
          instructions: nil,
          components: [],
          image_list: [],
          videos: [],
          audio: []
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns json' do
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'returns the project json' do
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(response.body).to eq(starter_project_json)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project', headers:)
        expect(response).to have_http_status(:not_found)
      end

      it 'creates a new ProjectLoader with the correct parameters' do
        allow(ProjectLoader).to receive(:new).and_call_original
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(ProjectLoader).to have_received(:new)
          .with(starter_project.identifier, [starter_project.locale])
      end
    end

    context 'when loading an owned project' do
      let!(:project) { create(:project, user_id: teacher.id, locale: nil) }
      let(:project_json) do
        {
          identifier: project.identifier,
          project_type: Project::Types::PYTHON,
          locale: project.locale,
          name: project.name,
          user_id: project.user_id,
          components: [],
          image_list: [],
          videos: [],
          audio: []
        }.to_json
      end

      it 'returns unauthorized response' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not return the project json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.body).not_to include(project_json)
      end
    end
  end
end
