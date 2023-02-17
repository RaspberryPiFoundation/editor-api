# frozen_string_literal: true

module Types
  class ProjectInputType < Types::BaseInputObject
    argument :name, String, required: false
    argument :identifier, String, required: false
    argument :project_type, String, required: false
    argument :remixed_from_id, ID, required: false
    argument :components, [Types::ComponentInputType], required: false
  end
end
