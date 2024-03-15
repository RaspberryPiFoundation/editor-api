# frozen_string_literal: true

module SchoolOwner
  class List
    class << self
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_owners] = list_owners(school, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error listing school owners: #{e}"
        response
      end

      private

      def list_owners(school, token)
        response = ProfileApiClient.list_school_owners(token:, organisation_id: school.id)
        user_ids = response.fetch(:ids)

        User.from_userinfo(ids: user_ids)
      end
    end
  end
end
