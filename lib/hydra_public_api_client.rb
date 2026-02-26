# frozen_string_literal: true

require 'faraday'

class HydraPublicApiClient
  # Allows us to use a different URL for API calls to auth locally
  HYDRA_PUBLIC_API_URL = ENV.fetch('HYDRA_PUBLIC_API_URL', nil)
  API_URL = HYDRA_PUBLIC_API_URL || ENV.fetch('HYDRA_PUBLIC_URL', 'http://localhost:9001')

  class << self
    def fetch_oauth_user(...)
      new.fetch_oauth_user(...)
    end
  end

  def fetch_oauth_user(token:)
    return stubbed_user if bypass_oauth?

    response = get('userinfo', {}, { Authorization: "Bearer #{token}" })
    response.body.to_h
  rescue Faraday::UnauthorizedError => e
    Sentry.capture_exception(e)
    nil
  end

  private

  def bypass_oauth?
    ENV.fetch('BYPASS_OAUTH', nil) == 'true'
  end

  def stubbed_user
    {
      id: '00000000-0000-0000-0000-000000000000',
      email: 'school-owner@example.com',
      username: nil,
      parentalEmail: nil,
      name: 'School Owner',
      nickname: 'Owner',
      country: 'United Kingdom',
      country_code: 'GB',
      postcode: nil,
      dateOfBirth: nil,
      verifiedAt: '2024-01-01T12:00:00.000Z',
      createdAt: '2024-01-01T12:00:00.000Z',
      updatedAt: '2024-01-01T12:00:00.000Z',
      discardedAt: nil,
      lastLoggedInAt: '2024-01-01T12:00:00.000Z',
      roles: ''
    }
  end

  def conn
    @conn ||= Faraday.new(API_URL) do |f|
      f.request :url_encoded
      f.response :raise_error
      f.response :json
    end
  end

  def get(...)
    conn.get(...)
  end
end
