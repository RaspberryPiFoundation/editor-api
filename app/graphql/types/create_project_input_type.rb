# frozen_string_literal: true

module Types
  class CreateProjectInputType < Types::BaseInputObject
    description 'Represents a project during creation'

    argument :components, [Types::ProjectComponentInputType], required: false, description: 'Any project components'
    argument :name, String, required: true, description: 'The name of the project'
    argument :project_type, String, required: true, description: 'The type of project, e.g. python, html'
  end
end
