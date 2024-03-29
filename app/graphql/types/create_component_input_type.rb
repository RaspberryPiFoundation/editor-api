# frozen_string_literal: true

module Types
  class CreateComponentInputType < Types::BaseInputObject
    description 'Represents a component during creation'

    argument :content, String, required: false, description: 'The text content of the component'
    argument :default, Boolean, required: true, description: 'If this is the default component on a project'
    argument :extension, String, required: true, description: 'The file extension of the component, e.g. html, csv, py'
    argument :name, String, required: true, description: 'The name of the file'
    argument :project_id, String, required: true, description: 'The easy-to-rememeber identifier of the project'
  end
end
