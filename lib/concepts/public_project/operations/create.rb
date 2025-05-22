# frozen_string_literal: true

module PublicProject
  class Create
    class << self
      def call(project_hash:)
        response = OperationResponse.new

        project = Project.new(project_hash).tap do |p|
          p.skip_identifier_generation = true
        end
        project.save!

        response[:project] = project
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating project: #{e}"
        response
      end
    end
  end
end
