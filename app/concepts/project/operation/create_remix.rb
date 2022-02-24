class Project
  module Operation
    class CreateRemix
      require 'operation_response'
      require 'phrase_identifier'

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

        def remix_project(response, params)
          original_project = Project.find_by!(identifier: params[:phrase_id])

          remixed_project = original_project.dup
          remixed_project.identifier = PhraseIdentifier.generate
          remixed_project.user_id = params[:remix][:user_id]

          original_project.components.each do |component|
            remixed_project.components << component.dup
          end

          response[:project] = remixed_project

          response[:error] = 'Unable to create project' unless remixed_project.save
          response
        end
      end
    end
  end
end
