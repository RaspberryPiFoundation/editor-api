# frozen_string_literal: true

class Project
  class ToggleFinished
    class << self
      def call(project:)
        response = OperationResponse.new
        response[:project] = project
        response[:project].assign_attributes(finished: !project.finished)
        response[:project].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:project]&.errors
        response
      end
    end
  end
end
