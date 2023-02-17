# frozen_string_literal: true

module Types
  class ComponentInputType < Types::BaseInputObject
    argument :project_id, ID, required: false
    argument :name, String, required: false
    argument :extension, String, required: false
    argument :content, String, required: false
    argument :default, Boolean, required: false
  end
end
