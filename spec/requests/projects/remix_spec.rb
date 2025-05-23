# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remix requests' do
  let!(:original_project) { create(:project, project_type: original_project_type) }
  let(:original_project_type) { Project::Types::PYTHON }
  let(:project_params) do
    {
      name: original_project.name,
      identifier: original_project.identifier,
      components: []
    }
  end
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }

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
    end

    describe '#index' do
      before do
        create_list(:project, 2, remixed_from_id: original_project.id, user_id: authenticated_user.id)
      end

      it 'returns success response' do
        get("/api/projects/#{original_project.identifier}/remixes", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns the list of projects' do
        get("/api/projects/#{original_project.identifier}/remixes", headers:)
        expect(response.parsed_body.length).to eq(2)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project/remixes', headers:)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe '#show' do
      let(:project_type) { Project::Types::PYTHON }

      before do
        create(:project, remixed_from_id: original_project.id, user_id: authenticated_user.id, project_type:)
      end

      it 'returns success response' do
        get("/api/projects/#{original_project.identifier}/remix", headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project/remix', headers:)

        expect(response).to have_http_status(:not_found)
      end

      context 'when original project and remix are scratch projects' do
        let(:original_project_type) { Project::Types::SCRATCH }
        let(:project_type) { Project::Types::SCRATCH }

        it 'returns 404 response if scratch projects are not explicitly included' do
          get("/api/projects/#{original_project.identifier}/remix", headers:)

          expect(response).to have_http_status(:not_found)
        end

        it 'returns success response if scratch projects are explicitly included' do
          get("/api/projects/#{original_project.identifier}/remix?project_type=scratch", headers:)

          expect(response).to have_http_status(:ok)
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

      context 'when original project is scratch project' do
        let(:original_project_type) { Project::Types::SCRATCH }

        it 'returns 404 response if scratch projects are not explicitly included' do
          post("/api/projects/#{original_project.identifier}/remix", params: { project: project_params }, headers:)

          expect(response).to have_http_status(:not_found)
        end

        it 'returns success response if scratch projects are explicitly included' do
          post("/api/projects/#{original_project.identifier}/remix?project_type=scratch", params: { project: project_params }, headers:)

          expect(response).to have_http_status(:ok)
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

    describe '#create' do
      it 'returns unauthorized' do
        post "/api/projects/#{original_project.identifier}/remix"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
