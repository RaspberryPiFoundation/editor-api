# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :project, Types::ProjectType, 'Find a project by identifier' do
      argument :identifier, String, required: true, description: 'Project identifier'
    end

    field :projects, Types::ProjectType.connection_type, 'All projects'

    def project(identifier:)
      Project.find_by(identifier:)
    end

    def projects
      Project.accessible_by(context[:current_ability], :read)
    end
  end
end
