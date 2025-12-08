# frozen_string_literal: true

class UserInfoApiClient
  API_URL = ENV.fetch('USERINFO_API_URL', 'http://localhost:6000')
  API_KEY = ENV.fetch('USERINFO_API_KEY', '1234')

  class << self
    def fetch_by_ids(user_ids)
      return [] if user_ids.blank?
      return stubbed_users(user_ids) if bypass_oauth?

      response = conn.get do |r|
        r.url '/users'
        r.body = { userIds: user_ids }
      end
      return if response.body.blank?

      transform_result(response.body.fetch('users', []))
    end

    def find_user_by_email(email)
      return nil if email.blank?
      return stubbed_user_by_email(email) if bypass_oauth?

      response = conn.get do |r|
        r.url "/users/#{CGI.escape(email)}"
      end
      return nil if response.body.blank?

      # Single user response has 'user' key, not 'users'
      user = response.body.fetch('user', nil)
      user.present? ? transform_user(user) : nil
    rescue Faraday::ResourceNotFound
      nil
    end

    private

    def bypass_oauth?
      ENV.fetch('BYPASS_OAUTH', nil) == 'true'
    end

    def transform_user(user)
      user.transform_keys { |k| k.to_s.underscore.to_sym }
    end

    def transform_result(result)
      result.map { |user| transform_user(user) }
    end

    def conn
      Faraday.new(
        headers: { authorization: "Bearer #{API_KEY}" },
        url: API_URL
      ) do |f|
        f.request :instrumentation
        f.request :json # encode req bodies as JSON
        f.response :raise_error
        f.response :json # decode response bodies as JSON
      end
    end

    # Development/test stubbing methods - only active when BYPASS_OAUTH=true
    # Delegates to UserInfoApiMock to avoid code duplication
    def stubbed_users(user_ids)
      require_relative '../spec/support/user_info_api_mock' unless defined?(UserInfoApiMock)
      UserInfoApiMock.default_stubbed_users(user_ids)
    end

    def stubbed_user_by_email(email)
      require_relative '../spec/support/user_info_api_mock' unless defined?(UserInfoApiMock)
      UserInfoApiMock.default_stubbed_user_by_email(email)
    end
  end
end
