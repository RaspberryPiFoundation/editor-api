# frozen_string_literal: true

module Types
  class UpdateProjectInputType < Types::BaseInputObject
    description 'Represents a project during an update'

    argument :id, String, required: true, description: 'The ID of the project to update'
    argument :name, String, required: false, description: 'The name of the project'
    argument :project_type, String, required: false, description: 'The type of project, e.g. python, html'
  end
end
