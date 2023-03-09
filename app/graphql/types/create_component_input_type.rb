# frozen_string_literal: true

module Types
  class CreateComponentInputType < Types::BaseInputObject
    description 'Represents a component during creation'

    argument :id, String, required: true, description: 'The easy-to-rememeber identifier of the project'
    argument :components, [Types::ProjectComponentInputType], required: false, description: 'Any project components'
  end
end
