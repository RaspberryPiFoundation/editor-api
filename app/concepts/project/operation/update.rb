# frozen_string_literal: true

class Project
  module Operation
    class Update
      require 'operation_response'

      def self.call(params, project)
        response = OperationResponse.new
        response[:project] = project

        setup_deletions(response, params)
        return response if response.failure?

        response[:project].assign_attributes(params.slice(:name))
        params[:components].each do |component_params|
          if component_params[:id].present?
            component = response[:project].components.select { |c| c.id == component_params[:id] }.first
            component.assign_attributes(component_params)
          else
            response[:project].components.build(component_params)
          end
        end

        response[:project].save!
        response[:project].components.where(id: component_ids_to_delete).destroy_all

        response
      end

      class << self
        private

        def setup_deletions(response, params)
          existing_component_ids = response[:project].components.pluck(:id)
          updated_component_ids = params[:components].pluck(:id)
          response[:component_ids_to_delete] = existing_component_ids - updated_component_ids

          validate_deletions(response)
        end

        def validate_deletions(response)
          default_component_id = response[:project].components.find_by(default: true)&.id
          return unless response[:component_ids_to_delete].include?(default_component_id)

          response[:error] = 'Can not delete protected component'
        end
      end
    end
  end
end
