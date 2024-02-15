# frozen_string_literal: true

class School
  class Delete
    class << self
      def call(school_id:)
        response = OperationResponse.new
        delete_school(school_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error deleting school: #{e}"
        response
      end

      private

      def delete_school(school_id)
        school = School.find(school_id)
        school.destroy!
      end
    end
  end
end
