# frozen_string_literal: true

using RpiAuthBypass

bypass_auth = ActiveModel::Type::Boolean.new.cast(ENV.fetch('BYPASS_OAUTH', false))

if bypass_auth
  extra = RpiAuthBypass::DEFAULT_EXTRA.deep_merge(raw_info: { roles: 'editor-admin' })
  OmniAuth.config.add_rpi_mock(extra:)
end

RpiAuth.configure do |config|
  config.auth_url = ENV.fetch('HYDRA_PUBLIC_URL', nil)
  config.auth_token_url = ENV.fetch('HYDRA_PUBLIC_TOKEN_URL', ENV.fetch('HYDRA_PUBLIC_URL', nil))
  config.auth_client_id = ENV.fetch('HYDRA_CLIENT_ID', nil)
  config.auth_client_secret = ENV.fetch('HYDRA_CLIENT_SECRET', nil)
  config.brand = ENV.fetch('AUTH_BRAND', 'raspberrypi-org')
  config.host_url = ENV.fetch('HOST_URL', nil)
  config.identity_url = ENV.fetch('IDENTITY_URL', nil)
  config.user_model = 'User'
  config.scope = 'openid email profile roles force-consent'
  config.success_redirect = -> { current_user&.admin? ? admin_root_path : root_path }
  config.bypass_auth = bypass_auth
end
