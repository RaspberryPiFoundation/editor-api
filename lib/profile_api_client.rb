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

      response = { 'id' => '12345678-1234-1234-1234-123456789abc' }
      response.deep_symbolize_keys
    end

    # The API should enforce these constraints:
    # - The token has the school-owner role for the given organisation ID
    # - The user should not be under 13
    # - The email must be verified
    #
    # The API should respond:
    # - 404 Not Found if the user doesn't exist
    # - 422 Unprocessable if the constraints are not met
    #
    # rubocop:disable Lint/UnusedMethodArgument
    def invite_school_owner(token:, email_address:, organisation_id:)
      return nil if token.blank?

      # TODO: We should make Faraday raise a Ruby error for a non-2xx status
      # code so that SchoolOwner::Invite propagates the error in the response.
      response = { 'id' => '99999999-9999-9999-9999-999999999999' }
      response.deep_symbolize_keys
    end
    # rubocop:enable Lint/UnusedMethodArgument
  end
end
