# frozen_string_literal: true

class PublicProject
  class Create
    class << self
      def call(project_hash:)
        response = OperationResponse.new

        public_project = PublicProject.new(
          Project.new(project_hash).tap do |p|
            p.skip_identifier_generation = true
          end
        )
        public_project.save!

        response[:project] = public_project.project
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating project: #{e}"
        response
      end
    end
  end
end
