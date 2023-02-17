# frozen_string_literal: true

module Types
  class ComponentType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :project, ProjectType
    field :name, String, null: false
    field :extension, String, null: false
    field :content, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :index, Integer
    field :default, Boolean, null: false
  end
end
