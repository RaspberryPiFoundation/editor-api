# frozen_string_literal: true

class Project
  class Create
    class << self
      def call(project_hash:, current_user:)
        response = OperationResponse.new

        project = build_project(project_hash, current_user)
        project.save!

        response[:project] = project
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating project: #{e}"
        response
      end

      private

      def build_project(project_hash, _current_user)
        new_project = Project.new(project_hash.except(:components))
        new_project.components.build(project_hash[:components])
        new_project
      end
    end
  end
end
