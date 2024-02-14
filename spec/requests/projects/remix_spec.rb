# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remix requests' do
  let!(:original_project) { create(:project) }
  let(:project_params) do
    {
      name: original_project.name,
      identifier: original_project.identifier,
      components: []
    }
  end

  before do
    mock_phrase_generation
  end

  context 'when auth is correct' do
    let(:headers) { { Authorization: 'dummy-token', Origin: 'editor.com' } }

    before do
      stub_fetch_oauth_user
    end

    describe '#show' do
      before do
        create(:project, remixed_from_id: original_project.id, user_id: stubbed_user_id)
      end

      it 'returns success response' do
        get("/api/projects/#{original_project.identifier}/remix", headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project/remix', headers:)

        expect(response).to have_http_status(:not_found)
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
          stub_fetch_oauth_user
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

    describe '#create' do
      it 'returns unauthorized' do
        post "/api/projects/#{original_project.identifier}/remix"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
