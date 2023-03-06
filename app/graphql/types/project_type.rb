# frozen_string_literal: true

module Types
  class ProjectType < Types::BaseObject
    description 'A project comprising of a number of components and images'
    implements GraphQL::Types::Relay::Node

    field :components, Types::ComponentType.connection_type,
          description: 'All components associated with this project'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'The created at timestamp'
    field :identifier, String, null: false, description: 'The easy-to-rememeber identifier of the project'
    field :images, Types::ImageType.connection_type,
          description: 'All images associated with this project'
    field :locale, String, description: 'The locale of project, e.g. en, fr-FR'
    field :name, String, description: 'The name of the project'
    field :project_type, String, null: false, description: 'The type of project, e.g. python, html'
    field :remixed_from, ProjectType, method: :parent, description: 'If present, the project this one was remixed from'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'The last updated timestamp'
    field :user_id, Types::UuidType, description: 'The project creator\'s user ID'

    delegate :components, to: :object

    def images
      object.images.to_a
    end

    def self.authorized?(object, context)
      super && context[:current_ability]&.can?(:show, object)
    end
  end
end
