# frozen_string_literal: true

class SchoolProject
  class SetFinished
    class << self
      def call(school_project:, finished:)
        response = OperationResponse.new
        response[:school_project] = school_project
        response[:school_project].assign_attributes(finished: finished)
        response[:school_project].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:school_project]&.errors
        response
      end
    end
  end
end
