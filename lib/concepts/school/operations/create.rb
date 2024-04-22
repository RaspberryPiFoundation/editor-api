# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:)
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
        School.new(school_params)
      end
    end
  end
end
