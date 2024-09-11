# frozen_string_literal: true

module Mutations
  class RemixProject < BaseMutation
    description 'A mutation to remix an existing project'
    input_object_class Types::RemixProjectInputType

    field :project, Types::ProjectType, description: 'The project that has been created'

    def resolve(**input)
      original_project = GlobalID.find(input[:id])
      raise GraphQL::ExecutionError, 'Project not found' unless original_project
      raise GraphQL::ExecutionError, 'You are not permitted to read this project' unless can_read?(original_project)

      params = {
        name: remix_name(input, original_project),
        identifier: original_project.identifier,
        components: remix_components(input, original_project)
      }

      response = Project::CreateRemix.call(
        params:,
        remix_origin:,
        user_id: context[:current_user]&.id,
        original_project:
      )

      raise GraphQL::ExecutionError, response[:error] unless response.success?

      { project: response[:project] }
    end

    def ready?(**_args)
      return true if can_create_project?

      raise GraphQL::ExecutionError, 'You are not permitted to create a project'
    end

    def can_create_project?
      context[:current_ability]&.can?(:create, Project, user_id: context[:current_user]&.id)
    end

    def can_read?(original_project)
      context[:current_ability]&.can?(:show, original_project)
    end

    def remix_components(input, original_project)
      input[:components]&.map(&:to_h) || original_project.components
    end

    def remix_origin
      context[:remix_origin]
    end

    def remix_name(input, original_project)
      input[:name] || original_project.name
    end
  end
end
