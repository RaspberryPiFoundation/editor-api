# frozen_string_literal: true

module Types
  class RemixProjectInputType < Types::BaseInputObject
    description 'Represents a project during a remix'

    argument :id, String, required: true, description: 'The ID of the project to remix'
    argument :name, String, required: false, description: 'The name of the remixed project'
    argument :components, [Types::ProjectComponentInputType], required: false, description: 'The components of the remixed project'
  end
end
