# frozen_string_literal: true

class ProfileApiClient
  class << self
    # TODO: Replace with HTTP requests once the profile API has been built.

    # The API should enforce these constraints:
    # - The user should have an email address
    # - The user should not be under 13
    def create_organisation(token:)
      return nil if token.blank?

      response = { 'id' => '12345678-1234-1234-1234-123456789abc' }
      response.deep_symbolize_keys
    end
  end
end
