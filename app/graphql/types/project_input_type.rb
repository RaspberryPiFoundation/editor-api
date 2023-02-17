# frozen_string_literal: true

module Types
  class ProjectInputType < Types::BaseInputObject
    argument :user_id, Types::UuidType, required: false
    argument :name, String, required: false
    argument :identifier, String, required: false
    argument :project_type, String, required: false
    argument :remixed_from_id, Types::UuidType, required: false
  end
end
