# frozen_string_literal: true

module Types
  class ProjectInputType < Types::BaseInputObject
    description 'Represents a project during a mutation'

    argument :components, [Types::ComponentInputType], required: false, description: 'Any project components'
    argument :identifier, String, required: false, description: 'The project identifier'
    argument :name, String, required: false, description: 'The name of the project'
    argument :project_type, String, required: false, description: 'The type of project, e.g. python, html'
    argument :remixed_from_id, ID, required: false,
                                   description: 'The ID of the project this project has been remixed from'
  end
end
