# frozen_string_literal: true

module Subscriptions
  class PardotFormHandlerSubmitter
    Result = Struct.new(:success?, :status, :error_code, :message, keyword_init: true)

    REQUEST_TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5

    def initialize(endpoint_url:)
      @endpoint_url = endpoint_url
    end

    def call(form_payload:)
      return missing_configuration_result if endpoint_url.blank?

      response = faraday.post(endpoint_url, form_payload)
      return Result.new(success?: true) if response.success?

      Result.new(
        success?: false,
        status: :bad_gateway,
        error_code: 'subscription_provider_rejected',
        message: 'Subscription provider rejected the request.'
      )
    rescue Faraday::Error
      # Sentry.capture_exception(e)
      Result.new(
        success?: false,
        status: :service_unavailable,
        error_code: 'subscription_provider_unavailable',
        message: 'Subscription provider is currently unavailable.'
      )
    end

    private

    attr_reader :endpoint_url

    def faraday
      @faraday ||= Faraday.new do |f|
        f.request :url_encoded
        f.options.timeout = REQUEST_TIMEOUT_SECONDS
        f.options.open_timeout = OPEN_TIMEOUT_SECONDS
      end
    end

    def missing_configuration_result
      Result.new(
        success?: false,
        status: :service_unavailable,
        error_code: 'subscription_provider_not_configured',
        message: 'Subscription provider endpoint is not configured.'
      )
    end
  end
end
