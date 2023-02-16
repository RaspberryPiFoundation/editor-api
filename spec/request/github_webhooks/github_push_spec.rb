# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GithubWebhooksController, type: :request do
  # let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  # let(:project) { create(:project, user_id:) }

  around do |example|
    ClimateControl.modify GITHUB_WEBHOOK_SECRET: 'secret', GITHUB_WEBHOOK_REF: 'branches/whatever' do
      example.run
    end
  end

  describe 'github_push' do
    let(:params) {{
      ref: '/branches/main',
      commits: []
    }}

    let(:headers) {
      {
        'X-Hub-Signature-256': "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), ENV.fetch('GITHUB_WEBHOOK_SECRET'), params.to_json)}",
        'X-GitHub-Event': 'push'
      }
    }

    before do
      post '/github_webhooks', params: params.to_json, headers: headers
    end

    it 'returns success' do
      expect(response).to have_http_status(:ok)
    end
  end
end
