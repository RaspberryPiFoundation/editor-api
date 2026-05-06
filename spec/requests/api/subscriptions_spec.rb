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
          privacy_policy: true,
          turnstile_token: 'test-token'
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
    let(:submitter_result_rejected) do
      Subscriptions::PardotFormHandlerSubmitter::Result.new(
        success?: false,
        status: :bad_gateway,
        error_code: 'subscription_provider_rejected',
        message: 'Subscription provider rejected the request.'
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

    it 'returns provider rejection shape when provider rejects request' do
      allow(submitter).to receive(:call).and_return(submitter_result_rejected)

      post(path, params: payload, as: :json)

      expect(response).to have_http_status(:bad_gateway)
      expect(response.parsed_body).to include(
        'ok' => false,
        'error_code' => 'subscription_provider_rejected',
        'message' => 'Subscription provider rejected the request.'
      )
    end

    describe 'Cloudflare Turnstile integration' do
      let(:request_url) { 'https://challenges.cloudflare.com/turnstile/v0/siteverify' }

      before do
        allow(Rails.configuration.x.cloudflare_turnstile).to receive_messages(
          enabled: true,
          secret_key: 'test-secret'
        )
      end

      it 'returns 422 when turnstile token is missing' do
        post(path, params: payload.deep_merge(subscription: { turnstile_token: '' }), as: :json)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error_code']).to eq('turnstile_verification_failed')
      end

      it 'returns 422 when turnstile verification fails' do
        stub_request(:post, request_url)
          .with(
            body: hash_including(
              secret: 'test-secret',
              response: 'test-token'
            )
          )
          .to_return(status: 200, body: { success: false }.to_json)

        post(path, params: payload, as: :json)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error_code']).to eq('turnstile_verification_failed')
      end

      it 'allows request through if turnstile verification is unavailable' do
        stub_request(:post, request_url)
          .with(
            body: hash_including(
              secret: 'test-secret',
              response: 'test-token'
            )
          )
          .to_timeout

        post(path, params: payload, as: :json)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['ok']).to be(true)
      end
    end
  end
end
