# frozen_string_literal: true

module Mutations
  class ShareProject < BaseMutation
    description 'A mutation to share an existing project'
    input_object_class Types::ShareProjectInputType

    field :project, Types::ProjectType, description: 'The project that has been created'

    def resolve(**input)
      original_project = GlobalID.find(input[:id])
      raise GraphQL::ExecutionError, 'Project not found' unless original_project
      raise GraphQL::ExecutionError, 'You are not permitted to read this project' unless can_read?(original_project)

      params = {
        name: input[:name] || original_project.name,
        identifier: original_project.identifier,
        components: share_components(input, original_project)
      }
      response = Project::CreateShare.call(params:, original_project:)
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

    def can_read?(original_project)
      context[:current_ability]&.can?(:show, original_project)
    end

    def share_components(input, original_project)
      input[:components]&.map(&:to_h) || original_project.components
    end
  end
end
