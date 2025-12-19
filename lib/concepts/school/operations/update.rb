# frozen_string_literal: true

class School
  class Update
    class << self
      def call(school:, school_params:)
        response = OperationResponse.new
        response[:school] = school
        response[:school].assign_attributes(school_params)
        response[:school].save!
        response
      rescue School::DuplicateSchoolError => e
        Sentry.capture_exception(e)
        response[:error] = e.message
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school].errors.full_messages.join(',')
        response[:error] = "Error updating school: #{errors}"
        response
      end
    end
  end
end
