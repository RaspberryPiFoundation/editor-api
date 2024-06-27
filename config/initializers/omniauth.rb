# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

if ENV.fetch('BYPASS_OAUTH', nil) == 'true'
  using RpiAuthBypass

  extra = RpiAuthBypass::DEFAULT_EXTRA.deep_merge(raw_info: { roles: 'editor-admin' })
  OmniAuth.config.add_rpi_mock(extra:)
  OmniAuth.config.enable_rpi_auth_bypass
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    OmniAuth::Strategies::Rpi, ENV.fetch('HYDRA_CLIENT_ID', nil), ENV.fetch('HYDRA_CLIENT_SECRET', nil),
    scope: 'openid email profile roles force-consent',
    callback_path: '/auth/callback',
    client_options: {
      site: ENV.fetch('HYDRA_PUBLIC_URL', nil),
      authorize_url: "#{ENV.fetch('HYDRA_PUBLIC_URL', nil)}/oauth2/auth",
      token_url: "#{ENV.fetch('HYDRA_PUBLIC_TOKEN_URL', ENV.fetch('HYDRA_PUBLIC_URL', nil))}/oauth2/token",
      auth_scheme: :basic_auth
    },
    authorize_params: {},
    origin_param: 'returnTo'
  )

  OmniAuth.config.on_failure = AuthController.action(:failure)
end
