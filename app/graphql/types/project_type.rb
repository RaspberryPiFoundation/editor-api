# frozen_string_literal: true

module Types
  class ProjectType < Types::BaseObject
    implements GraphQL::Types::Relay::Node

    field :user_id, Types::UuidType
    field :name, String
    field :identifier, String, null: false
    field :project_type, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :remixed_from, ProjectType

    field :components, Types::ComponentType.connection_type,
          description: 'All components associated with this project'

    field :images, Types::ImageType.connection_type,
          description: 'All images associated with this project'

    delegate :components, to: :object

    def images
      object.images.to_a
    end

    def remixed_from
      object.parent
    end

    def self.authorized?(object, context)
      super && context[:current_ability].can?(:read, object)
    end
  end
end
