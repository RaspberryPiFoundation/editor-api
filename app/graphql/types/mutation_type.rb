# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # rubocop:disable GraphQL/ExtractType
    field :create_component, mutation: Mutations::CreateComponent, description: 'Create a component'
    field :create_project, mutation: Mutations::CreateProject, description: 'Create a project, complete with components'
    field :delete_project, mutation: Mutations::DeleteProject, description: 'Delete an existing project'
    field :update_project, mutation: Mutations::UpdateProject, description: 'Update fields on an existing project'
    # rubocop:enable GraphQL/ExtractType
  end
end
