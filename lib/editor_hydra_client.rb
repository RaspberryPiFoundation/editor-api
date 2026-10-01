# frozen_string_literal: true

module EditorHydraClient
  SCOPE = 'openid email profile roles force-consent allow-u13-login'

  class << self
    def client_id
      ENV.fetch('EDITOR_HYDRA_CLIENT_ID', nil)
    end

    def issuer
      ENV.fetch('HYDRA_PUBLIC_URL', nil)
    end

    def authorize_url
      "#{issuer}/oauth2/auth"
    end

    def token_url
      "#{ENV.fetch('HYDRA_PUBLIC_TOKEN_URL', issuer)}/oauth2/token"
    end

    def auth_key
      "oidc.user:#{issuer}:#{client_id}"
    end

    def oauth_client
      OAuth2::Client.new(client_id, nil, site: issuer, token_url:, auth_scheme: :request_body)
    end

    def configure_strategy(env)
      return unless EditorApp.serves_host?(Rack::Request.new(env).host)

      strategy = env['omniauth.strategy']
      strategy.options[:client_id] = client_id
      strategy.options[:client_secret] = nil
      strategy.options[:client_options][:auth_scheme] = :request_body
      strategy.options[:pkce] = true
    end
  end
end
