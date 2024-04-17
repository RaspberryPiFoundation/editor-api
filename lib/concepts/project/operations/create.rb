# frozen_string_literal: true

class Project
  class Create
    class << self
      def call(project_hash:)
        response = OperationResponse.new
        response[:project] = build_project(project_hash)
        response[:project].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = 'Error creating project'
        response
      end

      private

      def build_project(project_hash)
        identifier = PhraseIdentifier.generate
        new_project = Project.new(project_hash.except(:components).merge(identifier:))
        new_project.components.build(project_hash[:components])
        new_project
      end
    end
  end
end
