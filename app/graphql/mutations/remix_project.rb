# frozen_string_literal: true

module Mutations
  class RemixProject < BaseMutation
    description 'A mutation to remix an existing project'
    input_object_class Types::RemixProjectInputType

    field :project, Types::ProjectType, description: 'The project that has been created'

    def resolve(**input)
      project = Project.find_by(identifier: input[:identifier], locale: input[:locale])

      # unless context[:current_ability]&.can?(:read, project)
      #   pp context[:current_ability]
      #   pp context[:current_user_id]
      #   raise GraphQL::ExecutionError, 'You are not permitted to read that project'
      # end

      remix_params = {
        name: project.name,
        identifier: project.identifier,
        components: project.components
      }
      response = Project::CreateRemix.call(params: remix_params, user_id: context[:current_user_id], original_project: project)
      raise GraphQL::ExecutionError, response[:error] unless response.success?

      { project: response[:project] }
    end

    def ready?(**_args)
      return true if can_create_project?

      raise GraphQL::ExecutionError, 'You are not permitted to create a project'
    end

    def can_create_project?
      context[:current_ability]&.can?(:create, Project, user_id: context[:current_user_id])
    end
  end
end
