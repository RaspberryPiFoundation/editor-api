# frozen_string_literal: true

class SchoolClass
  class Update
    class << self
      def call(school_class:, school_class_params:)
        response = OperationResponse.new
        response[:school_class] = school_class
        response[:school_class].assign_attributes(school_class_params)
        response[:school_class].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school_class].errors.full_messages.join(',')
        response[:error] = "Error updating school class: #{errors}"
        response
      end
    end
  end
end
