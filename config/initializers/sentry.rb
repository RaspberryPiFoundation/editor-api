# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil) if Rails.env.production?
  config.breadcrumbs_logger = [:active_support_logger]
  config.environment = ENV.fetch('SENTRY_CURRENT_ENV', nil) || ENV.fetch('RAILS_ENV', nil)

  config.rails.structured_logging.enabled = false
  config.traces_sample_rate = 0.1

  config.before_send = lambda do |event, hint|
    exception = hint[:exception]
    next event unless exception.is_a?(Faraday::Error)

    event.fingerprint = [exception.class.name, exception.try(:request_host) || 'unknown-host']
    event
  end
end
