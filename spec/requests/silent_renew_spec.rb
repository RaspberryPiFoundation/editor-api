# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Silent renew' do
  around do |example|
    ClimateControl.modify(
      EDITOR_APP_HOSTS: 'editor.example.com',
      EDITOR_HYDRA_CLIENT_ID: 'editor-dev',
      HYDRA_PUBLIC_URL: 'https://auth.example.com',
      HYDRA_PUBLIC_TOKEN_URL: 'https://auth.example.com'
    ) { example.run }
  end

  let(:user) { create(:user) }
  let(:token_endpoint) { 'https://auth.example.com/oauth2/token' }

  def sign_in_to_editor
    stub_auth_for(user)
    post 'https://editor.example.com/auth/rpi'
    follow_redirect!
  end

  def start_renewal
    get 'https://editor.example.com/auth/silent_renew/start'
    Rack::Utils.parse_query(URI.parse(response.location).query)
  end

  def id_token
    JWT.encode({ 'sub' => user.id, 'email' => user.email, 'name' => user.name }, nil, 'none')
  end

  describe 'GET /auth/silent_renew/start' do
    before { sign_in_to_editor }

    it 'asks Hydra to re-authorise without interrupting the user' do
      expect(start_renewal).to include('prompt' => 'none', 'client_id' => 'editor-dev', 'response_type' => 'code')
    end

    it 'comes back to the silent renew callback on the same origin' do
      expect(start_renewal['redirect_uri']).to eq('https://editor.example.com/auth/silent_renew')
    end

    it 'proves possession of the authorization code with PKCE' do
      expect(start_renewal).to include('code_challenge_method' => 'S256')
    end

    it 'refuses to renew when nobody is signed in' do
      reset!
      get 'https://editor.example.com/auth/silent_renew/start'
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /auth/silent_renew' do
    before do
      sign_in_to_editor
      stub_request(:post, token_endpoint).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { access_token: 'a-fresh-token', id_token:, token_type: 'bearer', expires_in: 3600 }.to_json
      )
    end

    def complete_renewal(state: start_renewal['state'], code: 'an-authorization-code')
      get "https://editor.example.com/auth/silent_renew?code=#{code}&state=#{state}"
    end

    it 'writes the fresh token to local storage for the editor to pick up' do
      complete_renewal
      expect(response.body).to include('a-fresh-token')
    end

    it 'keeps the session token in step so server side requests use the fresh one' do
      complete_renewal
      expect(session[:current_user]['token']).to eq('a-fresh-token')
    end

    it 'authenticates as a public client, with the code verifier and no secret' do
      complete_renewal
      expect(WebMock).to have_requested(:post, token_endpoint)
        .with { |request| request.body.include?('code_verifier') && request.headers['Authorization'].nil? }
    end

    it 'tells the page that opened it the session was renewed' do
      complete_renewal
      expect(response.body).to include('"editor-app:session-renewal"').and include('renewed: true')
    end

    it 'rejects a callback whose state does not match the one it issued' do
      start_renewal
      complete_renewal(state: 'not-the-state-we-issued')
      expect(response.body).to include('renewed: false')
    end

    context 'when the Hydra session has gone' do
      before do
        stub_request(:post, token_endpoint).to_return(
          status: 400,
          headers: { 'Content-Type' => 'application/json' },
          body: { error: 'login_required' }.to_json
        )
      end

      it 'reports the failure to the page that opened it' do
        complete_renewal
        expect(response.body).to include('renewed: false')
      end

      it 'leaves the stored token alone so unsaved work can still be recovered' do
        complete_renewal
        expect(response.body).not_to include('localStorage.removeItem')
      end
    end
  end
end
