# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remix requests', type: :request do
  let!(:original_project) { create(:project) }
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }

  describe 'create' do
    before do
      mock_phrase_generation
    end

    context 'when auth is correct' do
      let(:project_params) do
        {
          name: original_project.name,
          identifier: original_project.identifier,
          components: []
        }
      end

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

    context 'when auth is invalid' do
      it 'returns unauthorized' do
        post "/api/projects/#{original_project.identifier}/remix"

        expect(response.status).to eq(401)
      end
    end
  end
end
