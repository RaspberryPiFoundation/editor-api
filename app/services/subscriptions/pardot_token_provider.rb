# frozen_string_literal: true

module Subscriptions
  class PardotTokenProvider
    CACHE_KEY = 'subscriptions:pardot:access_token'
    EXPIRY_SKEW_SECONDS = 60
    REQUEST_TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5

    def initialize(auth_url:, client_id:, client_secret:, scope: nil)
      @auth_url = auth_url
      @client_id = client_id
      @client_secret = client_secret
      @scope = scope
    end

    def access_token(force_refresh: false)
      return nil if missing_configuration?

      Rails.cache.delete(CACHE_KEY) if force_refresh

      cached_token = Rails.cache.read(CACHE_KEY)
      return cached_token if cached_token.present?

      token, expires_in = fetch_token!
      ttl = [expires_in.to_i - EXPIRY_SKEW_SECONDS, 1].max
      Rails.cache.write(CACHE_KEY, token, expires_in: ttl)
      token
    rescue Faraday::Error, KeyError, JSON::ParserError
      nil
    end

    private

    attr_reader :auth_url, :client_id, :client_secret, :scope

    def missing_configuration?
      auth_url.blank? || client_id.blank? || client_secret.blank?
    end

    def fetch_token!
      response = faraday.post(auth_url) do |request|
        request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        request.body = {
          grant_type: 'client_credentials',
          client_id:,
          client_secret:,
          scope:
        }.compact
      end

      raise Faraday::BadRequestError.new('Token fetch failed', response:) unless response.success?

      body = JSON.parse(response.body)
      [body.fetch('access_token'), body.fetch('expires_in', 3600)]
    end

    def faraday
      @faraday ||= Faraday.new do |f|
        f.request :url_encoded
        f.options.timeout = REQUEST_TIMEOUT_SECONDS
        f.options.open_timeout = OPEN_TIMEOUT_SECONDS
      end
    end
  end
end
