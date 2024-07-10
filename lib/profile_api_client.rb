# frozen_string_literal: true

class ProfileApiClient
  SAFEGUARDING_FLAGS = {
    teacher: 'school:teacher',
    owner: 'school:owner'
  }.freeze

  School = Data.define(:id, :schoolCode, :updatedAt, :createdAt, :discardedAt)
  SafeguardingFlag = Data.define(:id, :userId, :flag, :email, :createdAt, :updatedAt, :discardedAt)

  class Error < StandardError; end

  class Student422Error < Error
    DEFAULT_ERROR = 'unknown error'
    ERRORS = {
      'ERR_USER_EXISTS' => 'username has already been taken',
      'ERR_INVALID' => 'unknown validation error',
      'ERR_INVALID_PASSWORD' => 'password is invalid',
      'ERR_UNKNOWN' => DEFAULT_ERROR
    }.freeze

    attr_reader :username, :error

    def initialize(error)
      @username = error['username']
      @error = ERRORS.fetch(error['error'], DEFAULT_ERROR)

      super "Student not saved in Profile API (status code 422, username '#{@username}', error '#{@error}')"
    end
  end

  class UnexpectedResponse < Error
    attr_reader :response_status, :response_headers, :response_body

    def initialize(response)
      @response_status = response.status
      @response_headers = response.headers
      @response_body = response.body

      super "Unexpected response from Profile API (status code #{response.status})"
    end
  end

  class << self
    def create_school(token:, id:, code:)
      return { 'id' => id, 'schoolCode' => code } if ENV['BYPASS_OAUTH'].present?

      response = connection(token).post('/api/v1/schools') do |request|
        request.body = {
          id:,
          schoolCode: code
        }
      end

      raise UnexpectedResponse, response unless response.status == 201

      School.new(**response.body)
    end

    def list_school_owners(*)
      {}
    end

    def invite_school_owner(*)
      {}
    end

    def remove_school_owner(*)
      {}
    end

    def list_school_teachers(*)
      {}
    end

    def remove_school_teacher(*)
      {}
    end

    def list_school_students(token:, organisation_id:)
      return [] if token.blank?

      _ = organisation_id

      {}
    end

    def create_school_student(token:, username:, password:, name:, school_id:)
      return nil if token.blank?

      response = connection(token).post("/api/v1/schools/#{school_id}/students") do |request|
        request.body = [{
          name: name.strip,
          username: username.strip,
          password: password.strip
        }]
      end

      raise UnexpectedResponse, response unless response.status == 201

      response.body.deep_symbolize_keys
    rescue Faraday::UnprocessableEntityError => e
      raise Student422Error, JSON.parse(e.response_body)['errors'].first
    end

    def update_school_student(token:, attributes_to_update:, organisation_id:)
      return nil if token.blank?

      _ = attributes_to_update
      _ = organisation_id

      {}
    end

    def delete_school_student(token:, student_id:, organisation_id:)
      return nil if token.blank?

      _ = student_id
      _ = organisation_id

      {}
    end

    def safeguarding_flags(token:)
      response = connection(token).get('/api/v1/safeguarding-flags')

      raise UnexpectedResponse, response unless response.status == 200

      response.body.map { |flag| SafeguardingFlag.new(**flag.symbolize_keys) }
    end

    def create_safeguarding_flag(token:, flag:)
      response = connection(token).post('/api/v1/safeguarding-flags') do |request|
        request.body = { flag: }
      end

      return if response.status == 201 || response.status == 303

      raise UnexpectedResponse, response
    end

    def delete_safeguarding_flag(token:, flag:)
      response = connection(token).delete("/api/v1/safeguarding-flags/#{flag}")

      return if response.status == 204

      raise UnexpectedResponse, response
    end

    private

    def connection(token)
      Faraday.new(ENV.fetch('IDENTITY_URL')) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.response :raise_error
        faraday.headers = {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{token}",
          'X-API-KEY' => ENV.fetch('PROFILE_API_KEY')
        }
      end
    end
  end
end
