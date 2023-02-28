# frozen_string_literal: true

module Types
  class ComponentType < Types::BaseObject
    description 'A file that makes up part of a project'
    implements GraphQL::Types::Relay::Node

    field :content, String, description: 'The contents of the component'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'The time it was created'
    field :default, Boolean, null: false,
                             description: 'True if this is the default component of a project, e.g. main.py, index.html'
    field :extension, String, null: false,
                              description: 'The file extension name of the component, e.g. py, html, css, csv'
    field :name, String, null: false, description: 'The file basename of the component, e.g. main, index, styles'
    field :project, ProjectType, description: 'The project this component belongs to'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'The time it was last changed'
  end
end
