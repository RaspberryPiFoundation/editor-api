# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil) if Rails.env.production?
  config.breadcrumbs_logger = [:active_support_logger]
  config.environment = ENV.fetch('SENTRY_CURRENT_ENV', nil) || ENV.fetch('RAILS_ENV', nil)

  config.traces_sample_rate = 0.5
end
