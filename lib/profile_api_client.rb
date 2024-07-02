# frozen_string_literal: true

class ProfileApiClient
  SAFEGUARDING_FLAGS = {
    teacher: 'school:teacher',
    owner: 'school:owner'
  }.freeze

  class << self
    # TODO: Replace with HTTP requests once the profile API has been built.

    def create_school(token:, school:)
      return { 'id' => school.id, 'schoolCode' => school.code } if ENV['BYPASS_OAUTH'].present?

      response = connection.post('/api/v1/schools') do |request|
        apply_default_headers(request, token)
        request.body = {
          id: school.id,
          schoolCode: school.code
        }.to_json
      end

      raise "School not created in Profile API. HTTP response code: #{response.status}" unless response.status == 201

      JSON.parse(response.body)
    end

    # The API should enforce these constraints:
    # - The token has the school-owner or school-teacher role for the given organisation ID
    # - The token user or given user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 422 Unprocessable if the constraints are not met
    def list_school_owners(token:, organisation_id:)
      return [] if token.blank?

      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Invite propagates the error in the response.
      response = { 'ids' => ['99999999-9999-9999-9999-999999999999'] }
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner role for the given organisation ID
    # - The token user or given user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def invite_school_owner(token:, email_address:, organisation_id:)
      return nil if token.blank?

      _ = email_address
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Invite propagates the error in the response.
      response = {}
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
    def create_school_student(token:, username:, password:, name:, school:)
      return nil if token.blank?

      response = connection.post("/api/v1/schools/#{school.id}/students") do |request|
        apply_default_headers(request, token)
        request.body = [{
          name:,
          username:,
          password:
        }].to_json
      end

      raise "Student not created in Profile API. HTTP response code: #{response.status}" unless response.status == 201

      JSON.parse(response.body)
    end

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
      response = connection.get('/api/v1/safeguarding-flags') do |request|
        apply_default_headers(request, token)
      end

      unless response.status == 200
        raise "Safeguarding flags cannot be retrieved from Profile API. HTTP response code: #{response.status}"
      end

      JSON.parse(response.body)
    end

    def create_safeguarding_flag(token:, flag:)
      response = connection.post('/api/v1/safeguarding-flags') do |request|
        apply_default_headers(request, token)
        request.body = { flag: }.to_json
      end

      return if response.status == 201

      raise "Safeguarding flag not created in Profile API. HTTP response code: #{response.status}"
    end

    def delete_safeguarding_flag(token:, flag:)
      response = connection.delete("/api/v1/safeguarding-flags/#{flag}") do |request|
        apply_default_headers(request, token)
      end

      return if response.status == 204

      raise "Safeguarding flag not deleted from Profile API. HTTP response code: #{response.status}"
    end

    private

    def connection
      Faraday.new(ENV.fetch('IDENTITY_URL'))
    end

    def apply_default_headers(request, token)
      request.headers['Accept'] = 'application/json'
      request.headers['Authorization'] = "Bearer #{token}"
      request.headers['Content-Type'] = 'application/json'
      request.headers['X-API-KEY'] = ENV.fetch('PROFILE_API_KEY')
      request
    end
  end
end
