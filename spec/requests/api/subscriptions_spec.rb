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

    let(:submitter_result_success) do
      Subscriptions::PardotFormHandlerSubmitter::Result.new(success?: true)
    end
    let(:submitter_result_failure) do
      Subscriptions::PardotFormHandlerSubmitter::Result.new(
        success?: false,
        status: :service_unavailable,
        error_code: 'subscription_provider_unavailable',
        message: 'Subscription provider is currently unavailable.'
      )
    end
    let(:submitter) { instance_double(Subscriptions::PardotFormHandlerSubmitter) }

    before do
      allow(Subscriptions::PardotFormHandlerSubmitter).to receive(:new).and_return(submitter)
      allow(submitter).to receive(:call).and_return(submitter_result_success)
    end

    it 'returns success for a valid payload' do
      post(path, params: payload, as: :json)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'ok' => true,
        'message' => 'Subscription accepted'
      )
      expect(submitter).to have_received(:call).with(
        form_payload: {
          'email' => 'teacher@example.com',
          'test_opt_in' => true,
          'privacy_policy' => true
        }
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

    it 'returns provider error status/message when provider submission fails' do
      allow(submitter).to receive(:call).and_return(submitter_result_failure)

      post(path, params: payload, as: :json)

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body).to include(
        'ok' => false,
        'error_code' => 'subscription_provider_unavailable',
        'message' => 'Subscription provider is currently unavailable.'
      )
    end
  end
end
