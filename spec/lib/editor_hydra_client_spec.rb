# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorHydraClient do
  around do |example|
    ClimateControl.modify(
      EDITOR_APP_HOSTS: 'editor.example.com',
      EDITOR_HYDRA_CLIENT_ID: 'editor-dev',
      HYDRA_PUBLIC_URL: 'https://auth.example.com',
      HYDRA_PUBLIC_TOKEN_URL: 'https://auth-internal.example.com'
    ) { example.run }
  end

  let(:strategy) do
    OmniAuth::Strategies::Rpi.new(
      nil, 'editor-dashboard-dev', 'dashboard-secret',
      client_options: { auth_scheme: :basic_auth }, pkce: false
    )
  end

  def env_for(url)
    Rack::MockRequest.env_for(url).merge('omniauth.strategy' => strategy)
  end

  describe '.configure_strategy' do
    it 'switches the editor host to the editor client' do
      described_class.configure_strategy(env_for('http://editor.example.com/auth/rpi'))
      expect(strategy.options[:client_id]).to eq('editor-dev')
    end

    it 'drops the client secret, which a public client must not be sent' do
      described_class.configure_strategy(env_for('http://editor.example.com/auth/rpi'))
      expect(strategy.options[:client_secret]).to be_nil
    end

    it 'authenticates the authorization code exchange with PKCE instead' do
      described_class.configure_strategy(env_for('http://editor.example.com/auth/rpi'))
      expect(strategy.options[:pkce]).to be(true)
    end

    it 'sends no Authorization header on the token request' do
      described_class.configure_strategy(env_for('http://editor.example.com/auth/rpi'))
      expect(token_request_params).to eq('client_id' => 'editor-dev', 'code' => 'abc')
    end

    it 'leaves other hosts on the dashboard client' do
      described_class.configure_strategy(env_for('http://editor-api.example.com/auth/rpi'))
      expect(strategy.options[:client_id]).to eq('editor-dashboard-dev')
    end

    it 'leaves other hosts authenticating with their client secret' do
      described_class.configure_strategy(env_for('http://editor-api.example.com/auth/rpi'))
      expect(token_request_params).to include(headers: { 'Authorization' => a_string_starting_with('Basic ') })
    end
  end

  describe '.auth_key' do
    it 'matches the key oidc-client-ts would have written for the editor client' do
      expect(described_class.auth_key).to eq('oidc.user:https://auth.example.com:editor-dev')
    end
  end

  describe '.token_url' do
    it 'prefers the internal Hydra address' do
      expect(described_class.token_url).to eq('https://auth-internal.example.com/oauth2/token')
    end
  end

  def token_request_params
    OAuth2::Authenticator.new(
      strategy.options[:client_id],
      strategy.options[:client_secret],
      strategy.options[:client_options][:auth_scheme]
    ).apply('code' => 'abc')
  end
end
