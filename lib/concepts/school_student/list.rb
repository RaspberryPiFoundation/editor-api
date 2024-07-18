# frozen_string_literal: true

module SchoolStudent
  class List
    class << self
      def call(school:, token:, student_ids: nil)
        response = OperationResponse.new
        response[:school_students] = list_students(school, token, student_ids)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error listing school students: #{e}"
        response
      end

      private

      def list_students(school, token, student_ids)
        student_ids ||= Role.student.where(school:).map(&:user_id)
        ProfileApiClient.list_school_students(token:, school_id: school.id, student_ids:).map do |student|
          User.new(student.to_h.slice(:id, :username, :name))
        end
      end
    end
  end
end
