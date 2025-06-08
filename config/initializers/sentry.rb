# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil) if Rails.env.production?
  config.breadcrumbs_logger = [:active_support_logger]
  config.environment = ENV.fetch('SENTRY_CURRENT_ENV', nil) || ENV.fetch('RAILS_ENV', nil)

  config.traces_sample_rate = 0.5
end

module Sentry
  module Overrides
    def capture_exception(exception, **options, &)
      warn "[Sentry stub] #{exception.class}: #{exception.message}"
      warn exception.backtrace.join("\n") if exception.backtrace
      super
    end
  end
end

Sentry.singleton_class.prepend(Sentry::Overrides) unless Sentry.configuration.sending_allowed?
