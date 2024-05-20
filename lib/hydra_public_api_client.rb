# frozen_string_literal: true

require 'faraday'

class HydraPublicApiClient
  API_URL = ENV.fetch('HYDRA_PUBLIC_URL', 'http://localhost:9001')
  BYPASS_AUTH_USER_ID = User::OWNER_ID

  class << self
    def fetch_oauth_user(...)
      new.fetch_oauth_user(...)
    end
  end

  def fetch_oauth_user(token:)
    if bypass_auth?
      users = stubbed_data['users']
      user = users.detect { |attr| attr['id'] == BYPASS_AUTH_USER_ID }
      return user
    end

    response = get('userinfo', {}, { Authorization: "Bearer #{token}" })
    response.body.to_h
  end

  private

  def bypass_auth?
    ENV.fetch('BYPASS_AUTH', nil) == 'true'
  end

  def stubbed_data
    path = Rails.root.join('spec/fixtures/users.json')
    json = File.read(path)

    JSON.parse(json)
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
