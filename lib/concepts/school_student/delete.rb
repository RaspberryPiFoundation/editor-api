# frozen_string_literal: true

module SchoolStudent
  class Delete
    class << self
      def call(school:, student_id:, token:)
        response = OperationResponse.new
        delete_student(school, student_id, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error deleting school student: #{e}"
        response
      end

      private

      def delete_student(school, student_id, token)
        ProfileApiClient.delete_school_student(token:, student_id:, school_id: school.id)
      end
    end
  end
end
