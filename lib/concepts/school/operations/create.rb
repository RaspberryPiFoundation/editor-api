# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_hash:)
        response = OperationResponse.new
        response[:school] = build_school(school_hash)
        response[:school].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = 'Error creating school'
        response
      end

      private

      def build_school(school_hash)
        School.new(school_hash)
      end
    end
  end
end
