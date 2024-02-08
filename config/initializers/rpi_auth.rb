RpiAuth.configure do |config|
  config.auth_url = ENV.fetch('AUTH_URL', nil)
  config.auth_token_url = ENV.fetch('AUTH_TOKEN_URL', nil)
  config.auth_client_id = ENV.fetch('AUTH_CLIENT_ID', nil)
  config.auth_client_secret = ENV.fetch('AUTH_CLIENT_SECRET', nil)
  # config.brand = 'raspberrypi-org'
  config.host_url = ENV.fetch('HOST_URL', nil)
  config.identity_url = ENV.fetch('IDENTITY_URL', nil)
  # config.user_model = 'User'
  config.scope = 'openid email profile force-consent'
  # config.success_redirect = ENV.fetch('OAUTH_SUCCESS_REDIRECT_URL', nil)
  config.bypass_auth = ActiveModel::Type::Boolean.new.cast(ENV.fetch('BYPASS_OAUTH', false))
end
