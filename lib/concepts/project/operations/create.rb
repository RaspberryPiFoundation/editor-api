# frozen_string_literal: true

class Project
  class Create
    class << self
      def call(project_hash:)
        response = OperationResponse.new
        # ActiveRecord::Base.transaction do
          response[:project] = build_project(project_hash)
          response[:project].save!
          # if response[:project].school
          #   response[:school_project] = SchoolProject.create!(school: response[:project].school, project: response[:project])
          #   response[:school_project].save!
          # end
        # end
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating project: #{e}"
        response
      end

      private

      def build_project(project_hash)
        identifier = PhraseIdentifier.generate
        new_project = Project.new(project_hash.except(:components).merge(identifier:))
        new_project.components.build(project_hash[:components])
        # if new_project.school_id.present?
        #   new_project.school_project = SchoolProject.new(school: new_project.school, project: new_project)
        # end
        new_project
      end
    end
  end
end
