# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Google Auth requests' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }

  before do
    authenticated_in_hydra_as(owner)
  end

  describe 'POST /api/google_auth/exchange_code' do
    let(:params) do
      {
        google_auth: {
          code: 'test-authorization-code',
          redirect_uri: 'https://example.com/callback'
        }
      }
    end

    let(:google_token_response) do
      {
        'access_token' => 'test-access-token',
        'expires_in' => 3599,
        'token_type' => 'Bearer',
        'scope' => 'openid email profile',
        'id_token' => 'test-id-token'
      }
    end

    around do |example|
      ClimateControl.modify(
        GOOGLE_CLIENT_ID: 'test-client-id',
        GOOGLE_CLIENT_SECRET: 'test-client-secret'
      ) do
        example.run
      end
    end

    context 'when token exchange is successful' do
      before do
        stub_request(:post, Api::GoogleAuthController::TOKEN_EXCHANGE_URL)
          .with(
            body: {
              code: 'test-authorization-code',
              client_id: 'test-client-id',
              client_secret: 'test-client-secret',
              redirect_uri: 'https://example.com/callback',
              grant_type: 'authorization_code'
            }
          )
          .to_return(
            status: 200,
            body: google_token_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns success response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns token response from Google' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response.parsed_body).to eq(google_token_response)
      end

      it 'includes access_token in response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response.parsed_body['access_token']).to eq('test-access-token')
      end
    end

    context 'when token exchange fails with error from Google' do
      let(:error_response) do
        {
          'error' => 'invalid_grant',
          'error_description' => 'Bad Request'
        }
      end

      before do
        stub_request(:post, Api::GoogleAuthController::TOKEN_EXCHANGE_URL)
          .to_return(
            status: 400,
            body: error_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns unauthorized response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response.parsed_body['error']).to eq('Bad Request')
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:post, Api::GoogleAuthController::TOKEN_EXCHANGE_URL)
          .to_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'returns service unavailable response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:service_unavailable)
      end

      it 'returns error message' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response.parsed_body['error']).to eq('Connection failed')
      end
    end

    context 'when code parameter is missing' do
      let(:params) do
        {
          google_auth: {
            redirect_uri: 'https://example.com/callback'
          }
        }
      end

      it 'returns bad request response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when redirect_uri parameter is missing' do
      let(:params) do
        {
          google_auth: {
            code: 'test-authorization-code'
          }
        }
      end

      it 'returns bad request response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when google_auth params are missing' do
      it 'returns bad request response' do
        post('/api/google/auth/exchange-code', headers:)
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when user is not authenticated' do
      before do
        unauthenticated_in_hydra
      end

      it 'returns unauthorized response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is not authorized' do
      let(:student) { create(:student, school:) }

      before do
        authenticated_in_hydra_as(student)
      end

      it 'returns forbidden response' do
        post('/api/google/auth/exchange-code', params:, headers:)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
