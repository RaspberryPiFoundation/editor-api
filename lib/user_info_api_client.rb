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

    def stubbed_users(user_ids)
      user_ids.map do |user_id|
        {
          id: user_id,
          email: "user-#{user_id}@example.com",
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
    end

    def stubbed_user_by_email(email)
      {
        id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, email),
        email: email,
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
  end
end
