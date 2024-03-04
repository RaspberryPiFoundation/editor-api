# frozen_string_literal: true

class SchoolClass
  class Delete
    class << self
      def call(school:, school_class_id:)
        response = OperationResponse.new
        delete_school_class(school, school_class_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error deleting school class: #{e}"
        response
      end

      private

      def delete_school_class(school, school_class_id)
        school_class = school.classes.find(school_class_id)
        school_class.destroy!
      end
    end
  end
end
