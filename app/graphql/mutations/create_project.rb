# frozen_string_literal: true

module Mutations
  class CreateProject < BaseMutation
    description 'A mutation to create a new project'
    input_object_class Types::CreateProjectInputType

    field :project, Types::ProjectType, description: 'The project that has been created'

    def resolve(**input)
      project_hash = input.merge(
        user_id: context[:current_user]&.id,
        components: input[:components]&.map(&:to_h)
      )

      response = Project::Create.call(project_hash:, current_user: context[:current_user])
      raise GraphQL::ExecutionError, response[:error] unless response.success?

      { project: response[:project] }
    end

    def ready?(**_args)
      return true if context[:current_ability]&.can?(:create, Project, user_id: context[:current_user]&.id)

      raise GraphQL::ExecutionError, 'You are not permitted to create a project'
    end
  end
end
