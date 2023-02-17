# frozen_string_literal: true

module Types
  class ComponentInputType < Types::BaseInputObject
    description 'Represents a project component during a mutation'

    argument :content, String, required: false, description: 'The text content of the component'
    argument :default, Boolean, required: false, description: 'If this is the default component on a project'
    argument :extension, String, required: false, description: 'The file extension of the component, e.g. html, csv, py'
    argument :name, String, required: false, description: 'The name of the file'
    argument :project_id, ID, required: false,
                              description: 'The ID of the project this component should be assocated with'
  end
end
