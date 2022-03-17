# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../lib/operation_response'

RSpec.describe 'Remix requests', type: :request do
  let!(:original_project) { create(:project) }
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project_params) do
    {
      name: original_project.name,
      identifier: original_project.identifier,
      components: []
    }
  end

  describe 'create' do
    before do
      mock_phrase_generation
    end

    context 'when auth is correct' do
      before do
        mock_oauth_user(user_id)
      end

      it 'returns success response' do
        post "/api/projects/#{original_project.identifier}/remix", params: { project: project_params }

        expect(response.status).to eq(200)
      end

      it 'returns 404 response if invalid project' do
        project_params[:identifier] = 'no-such-project'
        post '/api/projects/no-such-project/remix', params: { project: project_params }

        expect(response.status).to eq(404)
      end
    end

    context 'when project can not be saved' do
      before do
        mock_oauth_user(user_id)
        error_response = OperationResponse.new
        error_response[:error] = 'Something went wrong'
        allow(Project::Operation::CreateRemix).to receive(:call).and_return(error_response)
      end

      it 'returns 400' do
        post "/api/projects/#{original_project.identifier}/remix", params: { project: project_params }

        expect(response.status).to eq(400)
      end

      it 'returns error message' do
        post "/api/projects/#{original_project.identifier}/remix", params: { project: project_params }

        expect(response.body).to eq({ error: 'Something went wrong' }.to_json)
      end
    end

    context 'when auth is invalid' do
      it 'returns unauthorized' do
        post "/api/projects/#{original_project.identifier}/remix"

        expect(response.status).to eq(401)
      end
    end
  end
end
