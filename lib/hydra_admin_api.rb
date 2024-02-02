# frozen_string_literal: true

require 'faraday'

class HydraAdminApi
  ADMIN_URL     = ENV.fetch('HYDRA_ADMIN_URL', 'http://localhost:9002')
  ADMIN_API_KEY = ENV.fetch('HYDRA_ADMIN_API_KEY', 'test-key')

  # The "bypass" user ID from
  # https://github.com/RaspberryPiFoundation/rpi-auth/blob/main/lib/rpi_auth/engine.rb#L17
  BYPASS_AUTH         = ENV.fetch('BYPASS_AUTH', nil)
  BYPASS_AUTH_USER_ID = ENV.fetch('BYPASS_AUTH_USER_ID', 'b6301f34-b970-4d4f-8314-f877bad8b150')

  class << self
    def fetch_oauth_user_id(...)
      new.fetch_oauth_user_id(...)
    end
  end

  def fetch_oauth_user_id(token:)
    return nil if token.blank?

    return BYPASS_AUTH_USER_ID if BYPASS_AUTH == 'yes'

    response = post('oauth2/introspect', { token: }, { apikey: ADMIN_API_KEY })
    response.body['sub']
  end

  private

  def conn
    @conn ||= Faraday.new(ADMIN_URL) do |f|
      f.request :url_encoded
      f.response :raise_error
      f.response :json
    end
  end

  def post(...)
    conn.post(...)
  end
end
