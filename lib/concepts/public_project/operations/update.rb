# frozen_string_literal: true

class PublicProject
  class Update
    class << self
      def call(project:, update_hash:)
        response = OperationResponse.new

        project.assign_attributes(update_hash)
        project.save!

        response[:project] = project
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error updating project: #{e}"
        response
      end
    end
  end
end
