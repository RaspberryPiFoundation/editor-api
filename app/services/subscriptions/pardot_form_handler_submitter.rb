# frozen_string_literal: true

module Subscriptions
  class PardotFormHandlerSubmitter
    Result = Struct.new(:success?, :status, :error_code, :message, keyword_init: true)

    REQUEST_TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5
    SUCCESS_STATUS_CODE = 200
    ERROR_BODY_PATTERNS = ['error page'].freeze
    SUCCESS_BODY_PATTERNS = ['success page'].freeze

    def initialize(endpoint_url:)
      @endpoint_url = endpoint_url
    end

    def call(form_payload:)
      return missing_configuration_result if endpoint_url.blank?

      response = faraday.post(endpoint_url, provider_payload(form_payload))
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

    def provider_payload(form_payload)
      # Map internal API contract to Pardot Form Handler external field names.
      {
        'email' => form_payload['email'],
        'Tester' => form_payload['test_opt_in']
      }.compact
    end

    def classify_response(response)
      body = response_body(response)

      return reject_result if error_body?(body)
      return reject_result unless response.status == SUCCESS_STATUS_CODE
      return Result.new(success?: true) if success_body?(body)

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

    def error_body?(body)
      ERROR_BODY_PATTERNS.any? { |pattern| body.include?(pattern) }
    end

    def success_body?(body)
      SUCCESS_BODY_PATTERNS.any? { |pattern| body.include?(pattern) }
    end

    def response_body(response)
      response.body.to_s.downcase
    end

    def redirect_location(response)
      response.headers.fetch('location', '').to_s.downcase
    end

    def classification_for(response)
      body = response_body(response)

      return 'rejected_error_body' if error_body?(body)
      return 'rejected_status' unless response.status == SUCCESS_STATUS_CODE
      return 'accepted_success_body' if success_body?(body)

      'ambiguous_response'
    end
  end
end
