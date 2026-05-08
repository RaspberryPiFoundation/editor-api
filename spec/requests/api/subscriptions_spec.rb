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
      allow(Rails.configuration.x.cloudflare_turnstile).to receive(:enabled).and_return(false)
      allow(Subscriptions::PardotFormHandlerSubmitter).to receive(:new).and_return(submitter)
      allow(submitter).to receive(:call).and_return(submitter_result_success)
      allow(Sentry).to receive(:capture_exception)
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
      let(:turnstile_check) { instance_double(Subscriptions::TurnstileVerifier, passed?: true) }

      before do
        allow(Rails.configuration.x.cloudflare_turnstile).to receive_messages(
          enabled: true,
          secret_key: 'test-secret'
        )
        allow(Subscriptions::TurnstileVerifier).to receive(:new).and_return(turnstile_check)
      end

      it 'passes the token, remote IP and secret key to the verifier' do
        post(path, params: payload, as: :json)

        expect(Subscriptions::TurnstileVerifier).to have_received(:new).with(
          token: 'test-token',
          remote_ip: '127.0.0.1',
          secret_key: 'test-secret'
        )
      end

      context 'when the turnstile check passes' do
        it 'allows the request through' do
          post(path, params: payload, as: :json)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['ok']).to be(true)
        end
      end

      context 'when the turnstile check fails' do
        before { allow(turnstile_check).to receive(:passed?).and_return(false) }

        it 'returns 422 with turnstile_verification_failed error code' do
          post(path, params: payload, as: :json)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.parsed_body['error_code']).to eq('turnstile_verification_failed')
        end
      end
    end
  end
end
