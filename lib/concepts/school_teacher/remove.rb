# frozen_string_literal: true

module SchoolTeacher
  class Remove
    class << self
      def call(school:, teacher_id:, token:)
        response = OperationResponse.new
        remove_teacher(school, teacher_id, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error removing school teacher: #{e}"
        response
      end

      private

      def remove_teacher(school, teacher_id, token)
        ProfileApiClient.remove_school_teacher(token:, teacher_id:, organisation_id: school.id)
      end
    end
  end
end
