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
          project_type: 'python',
          locale: project.locale,
          name: project.name,
          user_id: project.user_id,
          instructions: project.instructions,
          components: [],
          images: [],
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
      let(:student) { create(:student, school:) }
      let(:lesson) { build(:lesson, school:, user_id: teacher.id, visibility: 'students') }
      let(:teacher_project) { create(:project, :with_instructions, school_id: school.id, lesson_id: lesson.id, user_id: teacher.id, locale: nil) }
      let(:student_project) { create(:project, school_id: school.id, lesson_id: nil, user_id: student.id, remixed_from_id: teacher_project.id, locale: nil, instructions: teacher_project.instructions, finished: true) }
      let(:student_project_json) do
        {
          identifier: student_project.identifier,
          project_type: 'python',
          locale: student_project.locale,
          name: student_project.name,
          user_id: student_project.user_id,
          instructions: student_project.instructions,
          parent: {
            name: teacher_project.name,
            identifier: teacher_project.identifier
          },
          components: [],
          images: [],
          videos: [],
          audio: [],
          user_name: 'Joe Bloggs',
          finished: student_project.finished
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

    context 'when loading another user\'s project' do
      let!(:another_project) { create(:project, user_id: SecureRandom.uuid, locale: nil) }
      let(:another_project_json) do
        {
          identifier: another_project.identifier,
          project_type: 'python',
          name: another_project.name,
          locale: another_project.locale,
          user_id: another_project.user_id,
          components: [],
          images: [],
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
      let!(:starter_project) { create(:project, user_id: nil, locale: 'ja-JP') }
      let(:starter_project_json) do
        {
          identifier: starter_project.identifier,
          project_type: 'python',
          locale: starter_project.locale,
          name: starter_project.name,
          user_id: starter_project.user_id,
          instructions: nil,
          components: [],
          images: [],
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
          project_type: 'python',
          locale: project.locale,
          name: project.name,
          user_id: project.user_id,
          components: [],
          images: [],
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
