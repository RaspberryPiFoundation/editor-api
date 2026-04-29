# frozen_string_literal: true

module Subscriptions
  class PardotFormHandlerSubmitter
    Result = Struct.new(:success?, :status, :error_code, :message, keyword_init: true)

    REQUEST_TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5
    SUCCESS_STATUS_CODES = [200, 302].freeze
    SUCCESS_LOCATION_PATTERNS = ['/success'].freeze
    ERROR_LOCATION_PATTERNS = ['/error'].freeze

    def initialize(endpoint_url:)
      @endpoint_url = endpoint_url
    end

    def call(form_payload:)
      return missing_configuration_result if endpoint_url.blank?

      response = faraday.post(endpoint_url, form_payload)
      Rails.logger.info(
        "[subscriptions#provider] status=#{response.status} " \
        "location=#{redirect_location(response)} " \
        "classification=#{classification_for(response)}"
      )
      classify_response(response)
    rescue Faraday::Error => e
      Sentry.capture_exception(e)
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

    def classify_response(response)
      return reject_result unless SUCCESS_STATUS_CODES.include?(response.status)
      return Result.new(success?: true) if response.status == 200
      return reject_result if redirect_to_error_location?(response)
      return Result.new(success?: true) if redirect_to_success_location?(response)

      ambiguous_result
    end

    def reject_result
      Result.new(
        success?: false,
        status: :bad_gateway,
        error_code: 'subscription_provider_rejected',
        message: 'Subscription provider rejected the request.'
      )
    end

    def ambiguous_result
      Result.new(
        success?: false,
        status: :bad_gateway,
        error_code: 'subscription_provider_ambiguous',
        message: 'Subscription provider response was ambiguous.'
      )
    end

    def redirect_to_success_location?(response)
      location = redirect_location(response)
      SUCCESS_LOCATION_PATTERNS.any? { |pattern| location.include?(pattern) }
    end

    def redirect_to_error_location?(response)
      location = redirect_location(response)
      ERROR_LOCATION_PATTERNS.any? { |pattern| location.include?(pattern) }
    end

    def redirect_location(response)
      response.headers.fetch('location', '').to_s.downcase
    end

    def classification_for(response)
      return 'rejected_status' unless SUCCESS_STATUS_CODES.include?(response.status)
      return 'accepted_200' if response.status == 200
      return 'rejected_error_redirect' if redirect_to_error_location?(response)
      return 'accepted_success_redirect' if redirect_to_success_location?(response)

      'ambiguous_redirect'
    end
  end
end
