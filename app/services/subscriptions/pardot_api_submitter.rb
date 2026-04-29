# frozen_string_literal: true

module Subscriptions
  class PardotApiSubmitter
    Result = Struct.new(:success?, :status, :error_code, :message, keyword_init: true)

    REQUEST_TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5

    def initialize(subscription_url:, business_unit_id:, token_provider:)
      @subscription_url = subscription_url
      @business_unit_id = business_unit_id
      @token_provider = token_provider
    end

    def call(subscription_payload:)
      return missing_configuration_result if subscription_url.blank?

      response = post_with_token(subscription_payload, force_refresh: false)
      response = post_with_token(subscription_payload, force_refresh: true) if response.status == 401

      return Result.new(success?: true) if response.success?

      Result.new(
        success?: false,
        status: :bad_gateway,
        error_code: 'subscription_provider_rejected',
        message: 'Subscription provider rejected the request.'
      )
    rescue Faraday::Error
      Result.new(
        success?: false,
        status: :service_unavailable,
        error_code: 'subscription_provider_unavailable',
        message: 'Subscription provider is currently unavailable.'
      )
    end

    private

    attr_reader :subscription_url, :business_unit_id, :token_provider

    def faraday
      @faraday ||= Faraday.new do |f|
        f.options.timeout = REQUEST_TIMEOUT_SECONDS
        f.options.open_timeout = OPEN_TIMEOUT_SECONDS
      end
    end

    def missing_configuration_result
      Result.new(
        success?: false,
        status: :service_unavailable,
        error_code: 'subscription_provider_not_configured',
        message: 'Subscription provider configuration is incomplete.'
      )
    end

    def post_with_token(subscription_payload, force_refresh:)
      token = token_provider.access_token(force_refresh:)
      raise Faraday::UnauthorizedError.new('Pardot access token unavailable') if token.blank?

      faraday.post(subscription_url) do |request|
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Pardot-Business-Unit-Id'] = business_unit_id if business_unit_id.present?
        request.headers['Content-Type'] = 'application/json'
        request.body = subscription_payload.to_json
      end
    end
  end
end
