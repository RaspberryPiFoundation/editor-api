# frozen_string_literal: true

class SchoolProject
  class SetStatus
    class << self
      def call(school_project:, status:, user_id:)
        response = OperationResponse.new
        response[:school_project] = school_project
        response[:school_project].transition_status_to!(status, user_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e.message
        response
      end
    end
  end
end
