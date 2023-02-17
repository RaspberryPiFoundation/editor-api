# frozen_string_literal: true

module Types
  class ComponentType < Types::BaseObject
    field :id, ID, null: false
    field :project_id, ID
    field :name, String, null: false
    field :extension, String, null: false
    field :content, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :index, Integer
    field :default, Boolean, null: false
  end
end
