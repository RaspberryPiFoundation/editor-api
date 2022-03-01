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
          valid = params[:phrase_id].present? && user_id.present?
          response[:error] = 'Invalid parameters' unless valid
        end

        def remix_project(response, params, user_id)
          original_project = Project.find_by!(identifier: params[:phrase_id])

          response[:project] = original_project.dup.tap do |proj|
            proj.user_id = user_id
            proj.components = original_project.components.map(&:dup)
          end

          response[:error] = 'Unable to create project' unless response[:project].save
          response
        end
      end
    end
  end
end
