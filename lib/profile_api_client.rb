# frozen_string_literal: true

class ProfileApiClient
  SAFEGUARDING_FLAGS = {
    teacher: 'school:teacher',
    owner: 'school:owner'
  }.freeze

  class Error < StandardError; end

  class CreateStudent422Error < Error
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

      super "Student not created in Profile API (status code 422, username '#{@username}', error '#{@error}')"
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

      raise "School not created in Profile API (status code #{response.status})" unless response.status == 201

      response.body
    end

    def list_school_owners(*)
      {}
    end

    def invite_school_owner(*)
      {}
    end

    # The API should enforce these constraints:
    # - The token has the school-owner role for the given organisation ID
    # - The token user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def remove_school_owner(token:, owner_id:, organisation_id:)
      return nil if token.blank?

      _ = owner_id
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Remove propagates the error in the response.
      response = {}
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner or school-teacher role for the given organisation ID
    # - The token user or given user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 422 Unprocessable if the constraints are not met
    def list_school_teachers(token:, organisation_id:)
      return [] if token.blank?

      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Invite propagates the error in the response.
      response = { 'ids' => ['99999999-9999-9999-9999-999999999999'] }
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner role for the given organisation ID
    # - The token user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def remove_school_teacher(token:, teacher_id:, organisation_id:)
      return nil if token.blank?

      _ = teacher_id
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Remove propagates the error in the response.
      response = {}
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner or school-teacher role for the given organisation ID
    # - The token user or given user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 422 Unprocessable if the constraints are not met
    def list_school_students(token:, organisation_id:)
      return [] if token.blank?

      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Invite propagates the error in the response.
      response = { 'ids' => ['99999999-9999-9999-9999-999999999999'] }
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner or school-teacher role for the given organisation ID
    # - The token user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    # rubocop:disable Metrics/AbcSize
    def create_school_student(token:, username:, password:, name:, school_id:)
      return nil if token.blank?

      response = connection(token).post("/api/v1/schools/#{school_id}/students") do |request|
        request.body = [{
          name: name.strip,
          username: username.strip,
          password: password.strip
        }]
      end

      raise CreateStudent422Error, response.body['errors'].first if response.status == 422
      raise "Student not created in Profile API (status code #{response.status})" unless response.status == 201

      response.body.deep_symbolize_keys
    end
    # rubocop:enable Metrics/AbcSize

    # The API should enforce these constraints:
    # - The token has the school-owner or school-teacher role for the given organisation ID
    # - The token user should not be under 13
    # - The email must be verified
    # - The student_id must be a school-student for the given organisation ID
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def update_school_student(token:, attributes_to_update:, organisation_id:)
      return nil if token.blank?

      _ = attributes_to_update
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Remove propagates the error in the response.
      response = {}
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner role for the given organisation ID
    # - The token user should not be under 13
    # - The email must be verified
    # - The student_id must be a school-student for the given organisation ID
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def delete_school_student(token:, student_id:, organisation_id:)
      return nil if token.blank?

      _ = student_id
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Remove propagates the error in the response.
      response = {}
      response.deep_symbolize_keys
    end

    def safeguarding_flags(token:)
      response = connection(token).get('/api/v1/safeguarding-flags')

      unless response.status == 200
        raise "Safeguarding flags cannot be retrieved from Profile API (status code #{response.status})"
      end

      response.body.map(&:deep_symbolize_keys)
    end

    def create_safeguarding_flag(token:, flag:)
      response = connection(token).post('/api/v1/safeguarding-flags') do |request|
        request.body = { flag: }
      end

      return if response.status == 201 || response.status == 303

      raise "Safeguarding flag not created in Profile API (status code #{response.status})"
    end

    def delete_safeguarding_flag(token:, flag:)
      response = connection(token).delete("/api/v1/safeguarding-flags/#{flag}")

      return if response.status == 204

      raise "Safeguarding flag not deleted from Profile API (status code #{response.status})"
    end

    private

    def connection(token)
      Faraday.new(ENV.fetch('IDENTITY_URL')) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.headers = {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{token}",
          'X-API-KEY' => ENV.fetch('PROFILE_API_KEY')
        }
      end
    end
  end
end
