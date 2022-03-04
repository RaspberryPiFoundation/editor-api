# frozen_string_literal: true

class Project
  module Operation
    class CreateRemix
      require 'operation_response'

      def self.call(params, user_id)
        response = OperationResponse.new

        validate_params(response, params, user_id)
        return response if response.failure?

        remix_project(response, params, user_id)
        response
      end

      class << self
        private

        def validate_params(response, params, user_id)
          valid = params[:project_id].present? && user_id.present?
          response[:error] = 'Invalid parameters' unless valid
        end

        def remix_project(response, params, user_id)
          original_project = Project.find_by!(identifier: params[:project_id])

          response[:project] = create_remix(original_project, user_id)

          response[:error] = 'Unable to create project' unless response[:project].save
          response
        end

        def create_remix(original_project, user_id)
          original_project.dup.tap do |proj|
            proj.user_id = user_id
            proj.components = original_project.components.map(&:dup)
            proj.remixed_from_id = original_project.id
          end
        end
      end
    end
  end
end
