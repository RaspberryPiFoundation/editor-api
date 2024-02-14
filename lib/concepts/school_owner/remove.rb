# frozen_string_literal: true

module SchoolOwner
  class Remove
    class << self
      def call(school:, owner_id:, token:)
        response = OperationResponse.new
        remove_owner(school, owner_id, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error removing school owner: #{e}"
        response
      end

      private

      def remove_owner(school, owner_id, token)
        ProfileApiClient.remove_school_owner(token:, owner_id:, organisation_id: school.id)
      end
    end
  end
end
