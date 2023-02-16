# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GithubWebhooksController, type: :request do
  # let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  # let(:project) { create(:project, user_id:) }

  describe 'github_push' do
    # context 'when auth is correct' do
      # before do
        # mock_oauth_user(user_id)

      #   response = OperationResponse.new
      #   response[:project] = project
      #   allow(Project::Create).to receive(:call).and_return(response)
      # end
      params = {
        ref: '/branches/main',
        commits: []
      }

      it 'returns success' do
        post '/github_webhooks', params: params, headers: {'x-hub-signature-256': ENV.fetch('GITHUB_WEBHOOK_SECRET')}
        expect(response).to have_http_status(:ok)
      end
    # end

    end
end
