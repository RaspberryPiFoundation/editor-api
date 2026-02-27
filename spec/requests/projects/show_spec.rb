# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project show requests' do
  let(:headers) { {} }
  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school) }

  context 'when user is logged in' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    before do
      authenticated_in_hydra_as(teacher)
      stub_profile_api_list_school_students(school:, student_attributes: [{ name: 'Joe Bloggs' }])
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

    context 'when setting scratch auth cookie' do
      let(:project_type) { Project::Types::PYTHON }
      let!(:project) { create(:project, school:, user_id: teacher.id, locale: nil, project_type:) }

      before do
        Flipper.disable :cat_mode
        Flipper.disable_actor :cat_mode, school
      end

      it 'does not set auth cookie when project is not scratch' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
        expect(response.cookies['scratch_auth']).to be_nil
      end

      context 'when project is code editor scratch' do
        let(:project_type) { Project::Types::CODE_EDITOR_SCRATCH }

        it 'does not set auth cookie when cat_mode is not enabled' do
          get("/api/projects/#{project.identifier}", headers:)

          expect(response).to have_http_status(:ok)
          expect(response.cookies['scratch_auth']).to be_nil
        end

        it 'sets auth cookie to auth header' do
          Flipper.enable_actor :cat_mode, school

          get("/api/projects/#{project.identifier}", headers:)

          expect(response).to have_http_status(:ok)
          expect(cookies['scratch_auth']).to eq(UserProfileMock::TOKEN)
        end
      end
    end

    context 'when loading a student\'s project' do
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
      let(:teacher_project) { create(:project, :with_instructions, school_id: school.id, lesson_id: lesson.id, user_id: teacher.id, locale: nil) }
      let(:student_project) { create(:project, school_id: school.id, lesson_id: nil, user_id: create(:student, school:).id, remixed_from_id: teacher_project.id, locale: nil, instructions: teacher_project.instructions) }
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

      it 'returns forbidden response' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not return the project json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.body).not_to include(project_json)
      end
    end
  end
end
