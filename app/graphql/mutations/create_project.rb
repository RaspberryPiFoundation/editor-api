# frozen_string_literal: true

module Mutations
  class CreateProject < BaseMutation
    description 'A mutation to create a new project'

    field :project, Types::ProjectType, description: 'The project that has been created'
    argument :project, Types::ProjectInputType, required: true, description: 'The project details to create'

    def resolve(project:)
      project_hash = project.to_h.merge(user_id: context[:current_user_id])
      r = Project::Create.call(project_hash:)
      raise GraphQL::ExecutionError, r[:error] unless r.success?

      { project: r[:project] }
    end

    def ready?(**_args)
      return true if context[:current_ability]&.can?(:create, Project, user_id: context[:current_user_id])

      raise GraphQL::ExecutionError, 'You are not permitted to create a project'
    end
  end
end
