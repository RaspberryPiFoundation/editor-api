# frozen_string_literal: true

class Project
  module Operation
    class CreateRemix
      require 'operation_response'

      def self.call(params:, user_id:, original_project:)
        response = OperationResponse.new

        validate_params(response, params, user_id, original_project)
        remix_project(response, params, user_id, original_project)
        response
      end

      class << self
        private

        def validate_params(response, params, user_id, original_project)
          valid = params[:identifier].present? && user_id.present? && original_project.present?
          response[:error] = 'Invalid parameters' unless valid
        end

        def remix_project(response, params, user_id, original_project)
          return if response[:error]

          response[:project] = create_remix(original_project, params, user_id)

          response[:error] = 'Unable to create project' unless response[:project].save
          response
        end

        def create_remix(original_project, params, user_id)
          remix = original_project.dup.tap do |proj|
            proj.user_id = user_id
            proj.remixed_from_id = original_project.id
          end

          params[:components].each do |x|
            remix.components.build(x.slice(:name, :extension, :content, :index))
          end
          remix
        end
      end
    end
  end
end
