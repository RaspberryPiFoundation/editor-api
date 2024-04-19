# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, token:)
        response = OperationResponse.new
        response[:school] = build_school(school_params)
        response[:school].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school].errors.full_messages.join(',')
        response[:error] = "Error creating school: #{errors}"
        response
      end

      private

      def build_school(school_params)
        school = School.new(school_params)
        school
      end
    end
  end
end
