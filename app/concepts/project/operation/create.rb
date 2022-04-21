# frozen_string_literal: true

class Project
  module Operation
    class Create
      require 'operation_response'

      def self.call(user_id:)
        response = OperationResponse.new
        response[:project] = Project.new(user_id: user_id, project_type: 'python')
        response[:project].components.build(name: 'main', extension: 'py', default: true, index: 0)
        response[:project].save!
        response
      rescue StandardError
        # TODO: log error
        response[:error] = 'Error creating project'
        response
      end
    end
  end
end
