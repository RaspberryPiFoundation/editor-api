# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remix requests' do
  let(:project_params) do
    {
      name: original_project.name,
      identifier: original_project.identifier,
      components: []
    }
  end
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }
  let!(:original_project) { create(:project, school:, user_id: owner.id) }

  before do
    mock_phrase_generation
  end

  context 'when auth is correct' do
    let(:headers) do
      {
        Authorization: UserProfileMock::TOKEN,
        Origin: 'editor.com'
      }
    end

    before do
      authenticated_in_hydra_as(owner)
      stub_profile_api_create_safeguarding_flag
    end

    describe '#index' do
      before do
        student_attributes = [{ id: authenticated_user.id, name: 'sally-student' }]
        stub_profile_api_list_school_students(school:, student_attributes:)
        create_list(:project, 2, remixed_from_id: original_project.id, user_id: authenticated_user.id)
      end

      it 'returns success response' do
        get("/api/projects/#{original_project.identifier}/remixes", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns the list of projects with student names' do
        get("/api/projects/#{original_project.identifier}/remixes", headers:)
        expect(response.parsed_body.length).to eq(2)
        expect(response.parsed_body.first['user_name']).to eq('sally-student')
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project/remixes', headers:)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe '#show' do
      before do
        create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id)
      end

      it 'returns success response' do
        get("/api/projects/#{original_project.identifier}/remix", headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project/remix', headers:)

        expect(response).to have_http_status(:not_found)
      end

      context 'when multiple remixes exist for the same user and project' do
        let!(:oldest_remix) do
          create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id,
                           created_at: 2.days.ago, updated_at: 2.days.ago)
        end

        before do
          create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id,
                           created_at: 1.hour.from_now, updated_at: 1.hour.from_now)
        end

        it 'returns the oldest created remix' do
          get("/api/projects/#{original_project.identifier}/remix", headers:)

          expect(response.parsed_body['identifier']).to eq(oldest_remix.identifier)
        end
      end
    end

    describe('#show_identifier') do
      let!(:remixed_project) do
        create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id)
      end

      it 'returns success response' do
        get("/api/projects/#{original_project.identifier}/remix/identifier", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns the project identifier' do
        get("/api/projects/#{original_project.identifier}/remix/identifier", headers:)
        expect(response.parsed_body['identifier']).to eq(remixed_project.identifier)
      end

      it 'returns the supplied identifier when it already belongs to the user remix' do
        get("/api/projects/#{remixed_project.identifier}/remix/identifier", headers:)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['identifier']).to eq(remixed_project.identifier)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project/remix/identifier', headers:)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 if no remixed project for user' do
        another_user = create(:owner, school:)
        authenticated_in_hydra_as(another_user)

        get("/api/projects/#{original_project.identifier}/remix/identifier", headers:)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 if the supplied remix identifier belongs to another user' do
        another_user_remix = create(
          :project,
          remixed_from_id: original_project.id,
          user_id: create(:owner, school:).id
        )

        get("/api/projects/#{another_user_remix.identifier}/remix/identifier", headers:)
        expect(response).to have_http_status(:not_found)
      end

      context 'when multiple remixes exist for the same user and project' do
        let!(:oldest_remix) do
          create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id,
                           created_at: 2.days.ago, updated_at: 2.days.ago)
        end

        before do
          create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id,
                           created_at: 1.hour.from_now, updated_at: 1.hour.from_now)
        end

        it 'returns the identifier of the oldest created remix' do
          get("/api/projects/#{original_project.identifier}/remix/identifier", headers:)
          expect(response.parsed_body['identifier']).to eq(oldest_remix.identifier)
        end
      end
    end

    describe '#create' do
      it 'returns success response' do
        post("/api/projects/#{original_project.identifier}/remix", params: { project: project_params }, headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 response if invalid project' do
        project_params[:identifier] = 'no-such-project'
        post('/api/projects/no-such-project/remix', params: { project: project_params }, headers:)

        expect(response).to have_http_status(:not_found)
      end

      context 'when the original project belongs to another user' do
        let!(:original_project) { create(:project, user_id: create(:user).id) }

        it 'returns forbidden without creating a remix' do
          allow(Project::CreateRemix).to receive(:call).and_call_original

          expect do
            post("/api/projects/#{original_project.identifier}/remix", params: { project: project_params }, headers:)
          end.not_to change(Project, :count)

          expect(response).to have_http_status(:forbidden)
          expect(Project::CreateRemix).not_to have_received(:call)
        end
      end

      context 'when a student cannot view the teacher-only original project' do
        let(:student) { create(:student, school:) }
        let(:teacher) { create(:teacher, school:) }
        let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
        let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'teachers') }
        let!(:original_project) do
          lesson.project.tap do |project|
            project.update!(school:, user_id: teacher.id, instructions: 'Teacher-only instructions')
          end
        end

        before do
          create(:class_student, school_class:, student_id: student.id)
          authenticated_in_hydra_as(student)
        end

        it 'returns forbidden without creating a remix' do
          allow(Project::CreateRemix).to receive(:call).and_call_original

          expect do
            post("/api/projects/#{original_project.identifier}/remix", params: { project: project_params }, headers:)
          end.not_to change(Project, :count)

          expect(response).to have_http_status(:forbidden)
          expect(Project::CreateRemix).not_to have_received(:call)
        end
      end

      context 'when project cannot be saved' do
        before do
          authenticated_in_hydra_as(owner)
          error_response = OperationResponse.new
          error_response[:error] = 'Something went wrong'
          allow(Project::CreateRemix).to receive(:call).and_return(error_response)
        end

        it 'returns 400' do
          post("/api/projects/#{original_project.identifier}/remix", params: { project: project_params }, headers:)

          expect(response).to have_http_status(:bad_request)
        end

        it 'returns error message' do
          post("/api/projects/#{original_project.identifier}/remix", params: { project: project_params }, headers:)

          expect(response.body).to eq({ error: 'Something went wrong' }.to_json)
        end
      end
    end
  end

  context 'when auth is invalid' do
    describe '#show' do
      it 'returns unauthorized' do
        get "/api/projects/#{original_project.identifier}/remix"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe '#show_identifier' do
      it 'returns unauthorized' do
        get "/api/projects/#{original_project.identifier}/remix/identifier"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe '#create' do
      it 'returns unauthorized' do
        post "/api/projects/#{original_project.identifier}/remix"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
