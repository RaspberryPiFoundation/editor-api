# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subscriptions API' do
  describe 'POST /api/subscriptions' do
    let(:path) { '/api/subscriptions' }
    let(:payload) do
      {
        subscription: {
          email: 'teacher@example.com',
          test_opt_in: true,
          privacy_policy: true
        }
      }
    end

    it 'returns success for a valid payload' do
      post(path, params: payload, as: :json)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'ok' => true,
        'message' => 'Subscription accepted'
      )
    end

    it 'returns 422 when email is missing' do
      post(path, params: payload.deep_merge(subscription: { email: '' }), as: :json)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to include('email is required')
    end

    it 'returns 422 when email is malformed' do
      post(path, params: payload.deep_merge(subscription: { email: 'invalid-email' }), as: :json)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to include('email is invalid')
    end

    it 'returns 422 when privacy_policy is not true' do
      post(path, params: payload.deep_merge(subscription: { privacy_policy: false }), as: :json)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to include('privacy_policy must be true')
    end

    it 'returns 400 when subscription params are missing' do
      post(path, params: {}, as: :json)

      expect(response).to have_http_status(:bad_request)
    end
  end
end
