# frozen_string_literal: true

module Subscriptions
  class TurnstileVerifier
    API_URL = 'https://challenges.cloudflare.com/turnstile/v0/siteverify'

    def initialize(token:, remote_ip:, secret_key:)
      @token = token
      @remote_ip = remote_ip
      @secret_key = secret_key
    end

    def passed?
      return false if @token.blank?

      response = faraday.post(
        API_URL,
        {
          secret: secret_key,
          response: token,
          remoteip: remote_ip
        }
      )
      unless response.success?
        Rails.logger.warn("[subscriptions#create] turnstile verification skipped: HTTP #{response.status}")
        return true # fail open
      end

      JSON.parse(response.body)['success'] == true
    rescue Faraday::Error, JSON::ParserError => e
      Sentry.capture_exception(e)
      Rails.logger.warn("[subscriptions#create] turnstile verification error: #{e.message}")
      # Fail open to allow the request through if verification is unavailable
      # due to network issues, Cloudflare downtime or malformed responses etc.
      true
    end

    private

    attr_reader :secret_key, :remote_ip, :token

    def faraday
      @faraday ||= Faraday.new do |f|
        f.request :url_encoded
        f.options.timeout = 5
        f.options.open_timeout = 2
      end
    end
  end
end
