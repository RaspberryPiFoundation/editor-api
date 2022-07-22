# frozen_string_literal: true

class Project
  module Operation
    class Create
      require 'operation_response'

      DEFAULT_COMPONENT = { name: 'main', extension: 'py', default: true, index: 0 }.freeze
      DEFAULT_PROJECT = { type: 'python', name: 'Untitled project', components: [DEFAULT_COMPONENT],
                          image_list: [] }.freeze

      class << self
        def call(user_id:, params:)
          response = OperationResponse.new

          project = DEFAULT_PROJECT.merge(params.deep_symbolize_keys)
          new_project = Project.new(project_type: project[:type], user_id: user_id, name: project[:name])
          new_project.components.build(project[:components])

          response[:project] = new_project
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
end
