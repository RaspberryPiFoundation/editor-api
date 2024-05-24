# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, creator_id:)
        response = OperationResponse.new
        response[:school] = build_school(school_params.merge!(creator_id:))
        response[:school].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:school].errors
        response
      end

      private

      def build_school(school_params)
        School.new(school_params)
      end
    end
  end
end
