# frozen_string_literal: true

class SchoolProject
  class SetStatus
    class << self
      def call(school_project:, status:)
        response = OperationResponse.new
        response[:school_project] = school_project
        response[:school_project].set_status(status)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e.message
        response
      end
    end
  end
end
