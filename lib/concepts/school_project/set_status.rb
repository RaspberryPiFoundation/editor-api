# frozen_string_literal: true

class SchoolProject
  class SetStatus
    class << self
      def call(school_project:, status:, user_id:)
        response = OperationResponse.new
        response[:school_project] = school_project

        return response if response[:school_project].in_state?(status)

        unless response[:school_project].can_transition_to?(status)
          message = "Cannot transition from '#{response[:school_project].status}' to '#{status}'"
          response[:error] = message
          return response
        end

        response[:school_project].transition_status_to!(status, user_id)
        response
      end
    end
  end
end
