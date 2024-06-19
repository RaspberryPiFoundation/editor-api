# frozen_string_literal: true

require 'faraday'

class HydraPublicApiClient
  API_URL = ENV.fetch('HYDRA_PUBLIC_URL', 'http://localhost:9001')

  class << self
    def fetch_oauth_user(...)
      new.fetch_oauth_user(...)
    end
  end

  def fetch_oauth_user(token:)
    if bypass_oauth?
      users = stubbed_data['users']
      user = users.detect { |attr| attr['id'] == '00000000-0000-0000-0000-000000000000' }
      return user
    end

    response = get('userinfo', {}, { Authorization: "Bearer #{token}" })
    response.body.to_h
  end

  private

  def bypass_oauth?
    ENV.fetch('BYPASS_OAUTH', nil) == 'true'
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
