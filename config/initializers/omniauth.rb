# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

if ENV['BYPASS_OAUTH'].present?
  using RpiAuthBypass

  extra = RpiAuthBypass::DEFAULT_EXTRA.deep_merge(raw_info: { roles: 'editor-admin' })
  OmniAuth.config.add_rpi_mock(extra: extra)
  OmniAuth.config.enable_rpi_auth_bypass
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    OmniAuth::Strategies::Rpi, ENV['AUTH_CLIENT_ID'], ENV['AUTH_CLIENT_SECRET'],
    scope: "openid email profile roles force-consent",
    callback_path: '/auth/callback',
    client_options: {
      site: ENV['AUTH_URL'],
      authorize_url: "#{ENV['AUTH_URL']}/oauth2/auth",
      token_url: "#{ENV.fetch('AUTH_TOKEN_URL', ENV['AUTH_URL'])}/oauth2/token",
      auth_scheme: :basic_auth
    },
    authorize_params: {},
    origin_param: 'returnTo'
  )

  OmniAuth.config.on_failure = AuthController.action(:failure)
end
