# frozen_string_literal: true

class UserinfoApiClient
  API_URL = ENV.fetch('USERINFO_API_URL', 'http://localhost:6000')
  API_KEY = ENV.fetch('USERINFO_API_KEY', '1234')

  class << self
    def fetch_by_email(user_email)
      return if user_email.blank?

      return stubbed_by_email(user_email) if bypass_auth?

      response = conn.get { |r| r.url "/users/#{user_email}" }
      return if response.body.blank?

      transform_result(response.body.fetch('user', []))
    end

    def fetch_by_ids(user_ids)
      return if user_ids.blank?
      return stubbed_by_ids(user_ids) if bypass_auth?

      response = conn.get do |r|
        r.url '/users'
        r.body = { userIds: user_ids }
      end
      return if response.body.blank?

      transform_result(response.body.fetch('users', []))
    end

    private

    def bypass_auth?
      ENV.fetch('BYPASS_AUTH', nil) == 'true'
    end

    def transform_result(result)
      { result: }.deep_transform_keys { |k| k.to_s.underscore.to_sym }.fetch(:result)
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

    def stubbed_data
      path = Rails.root.join('spec/fixtures/users.json')
      json = File.read(path)

      JSON.parse(json)
    end

    def stubbed_by_email(user_email)
      data = stubbed_data.fetch('users', nil).find { |d| d['email'] == user_email }
      transform_result(data)
    end

    def stubbed_by_ids(user_ids)
      data = stubbed_data.fetch('users', nil).find_all { |d| user_ids.include?(d['id']) }
      transform_result(data)
    end
  end
end
