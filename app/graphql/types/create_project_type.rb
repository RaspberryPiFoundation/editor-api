# frozen_string_literal: true

module Types
  class CreateProjectType < Types::BaseObject
    field :user_id, ID
    field :name, String
    field :identifier, String, null: false
    field :project_type, String, null: false
    field :remixed_from_id, ID
  end
end
