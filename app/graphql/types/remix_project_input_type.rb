# frozen_string_literal: true

module Types
  class RemixProjectInputType < Types::BaseInputObject
    description 'Represents a project during a remix'

    argument :identifier, String, required: true, description: 'The identifier of the project to remix'
    argument :locale, String, required: true, description: 'The locale of the project to be remixed'
    argument :name, String, required: false, description: 'The name of the project'
    argument :project_type, String, required: false, description: 'The type of project, e.g. python, html'
  end
end
