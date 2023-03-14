# frozen_string_literal: true

module Types
  class UpdateComponentInputType < Types::BaseInputObject
    description 'Represents a project during an update'

    argument :content, String, required: false, description: 'The text content of the component'
    argument :default, Boolean, required: false, description: 'If this is the default component on a project'
    argument :extension, String, required: false, description: 'The file extension of the component, e.g. html, csv, py'
    argument :id, String, required: false, description: 'The ID of the component to update'
    argument :name, String, required: false, description: 'The name of the file'
  end
end
