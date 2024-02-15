# frozen_string_literal: true

class ProfileApiClient
  class << self
    # TODO: Replace with HTTP requests once the profile API has been built.

    # The API should enforce these constraints:
    # - The user should have an email address
    # - The user should not be under 13
    # - The user must have a verified email
    #
    # The API should respond:
    # - 422 Unprocessable if the constraints are not met
    def create_organisation(token:)
      return nil if token.blank?

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that School::Create propagates the error in the response.
      response = { 'id' => '12345678-1234-1234-1234-123456789abc' }
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
    # - The token has the school-owner role for the given organisation ID
    # - The token user or given user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def invite_school_teacher(token:, email_address:, organisation_id:)
      return nil if token.blank?

      _ = email_address
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolTeacher::Invite propagates the error in the response.
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
    # - The token user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    def create_school_student(token:, username:, password:, name:, organisation_id:)
      return nil if token.blank?

      _ = username
      _ = password
      _ = name
      _ = organisation_id

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolStudent::Create propagates the error in the response.
      response = {}
      response.deep_symbolize_keys
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
  end
end
