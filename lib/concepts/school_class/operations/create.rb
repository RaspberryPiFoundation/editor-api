# frozen_string_literal: true

class SchoolClass
  class Create
    class << self
      def call(school:, school_class_params:)
        response = OperationResponse.new
        response[:school_class] = school.classes.build(school_class_params)
        response[:school_class].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school_class].errors.full_messages.join(',')
        response[:error] = "Error creating school class: #{errors}"
        response
      end
    end
  end
end
