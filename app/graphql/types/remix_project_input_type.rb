# frozen_string_literal: true

module Types
  class RemixProjectInputType < Types::BaseInputObject
    description 'Represents a project during a remix'

    argument :id, String, required: true, description: 'The ID of the project to update'
    argument :name, String, required: false, description: 'The name of the project'
    argument :components, [Types::ProjectComponentInputType], required: false, description: 'Any project components'
  end
end
