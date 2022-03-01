# frozen_string_literal: true

class Project
  module Operation
    class CreateRemix
      require 'operation_response'

      def self.call(params)
        response = OperationResponse.new

        validate_params(response, params)
        return response if response.failure?

        remix_project(response, params)
        response
      end

      class << self
        private

        def validate_params(response, params)
          valid = params[:phrase_id].present? && params[:remix][:user_id].present?
          response[:error] = 'Invalid parameters' unless valid
        end

        def create_remix(original_project, params)
          original_project.dup.tap do |proj|
            proj.user_id = params[:remix][:user_id]
            proj.components = original_project.components.map(&:dup)
            proj.remixed_from_id = original_project.id
          end
        end

        def remix_project(response, params)
          original_project = Project.find_by!(identifier: params[:phrase_id])

          response[:project] = create_remix(original_project, params)

          response[:error] = 'Unable to create project' unless response[:project].save
          response
        end
      end
    end
  end
end
