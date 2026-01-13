# frozen_string_literal: true

class SchoolClass
  class Delete
    class << self
      def call(school:, school_class_id:)
        response = OperationResponse.new
        mark_school_class_as_deleted(school, school_class_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error deleting school class: #{e}"
        response
      end

      private

      def mark_school_class_as_deleted(school, school_class_id)
        school_class = school.classes.find(school_class_id)
        school_class.mark_as_deleted!
      end
    end
  end
end
