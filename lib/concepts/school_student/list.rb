# frozen_string_literal: true

module SchoolStudent
  class List
    class << self
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_students] = list_students(school, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error listing school students: #{e}"
        response
      end

      private

      def list_students(school, token)
        response = ProfileApiClient.list_school_students(token:, organisation_id: school.id)
        user_ids = response.fetch(:ids)

        User.from_userinfo(ids: user_ids)
      end
    end
  end
end
