# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create project requests' do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project) { create(:project, user_id:) }

  context 'when auth is correct' do
    let(:headers) { { Authorization: 'dummy-token' } }

    context 'when creating project is successful' do
      before do
        stub_fetch_oauth_user_id(user_id)

        response = OperationResponse.new
        response[:project] = project
        allow(Project::Create).to receive(:call).and_return(response)
      end

      it 'returns success' do
        post('/api/projects', headers:)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when creating project fails' do
      before do
        stub_fetch_oauth_user_id(user_id)

        response = OperationResponse.new
        response[:error] = 'Error creating project'
        allow(Project::Create).to receive(:call).and_return(response)
      end

      it 'returns error' do
        post('/api/projects', headers:)

        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      post '/api/projects'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
