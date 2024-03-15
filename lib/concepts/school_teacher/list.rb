# frozen_string_literal: true

module SchoolTeacher
  class List
    class << self
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_teachers] = list_teachers(school, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error listing school teachers: #{e}"
        response
      end

      private

      def list_teachers(school, token)
        response = ProfileApiClient.list_school_teachers(token:, organisation_id: school.id)
        user_ids = response.fetch(:ids)

        User.from_userinfo(ids: user_ids)
      end
    end
  end
end
