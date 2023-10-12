# frozen_string_literal: true

module Types
  class ShareProjectInputType < Types::BaseInputObject
    description 'Represents a project during a share'

    argument :components, [Types::ProjectComponentInputType],
             required: false,
             description: 'The components of the shared project'
    argument :id, String, required: true, description: 'The ID of the project to share'
    argument :name, String, required: false, description: 'The name of the shared project'
  end
end
