# frozen_string_literal: true

module Mutations
  class RemixProject < BaseMutation
    description 'A mutation to remix an existing project'
    input_object_class Types::RemixProjectInputType

    field :project, Types::ProjectType, description: 'The project that has been created'

    def resolve(**input)
      original_project = GlobalID.find(input[:id])
      raise GraphQL::ExecutionError, 'Project not found' unless original_project

      unless context[:current_ability]&.can?(:show, original_project)
        raise GraphQL::ExecutionError, 'You are not permitted to read that project'
      end

      params = {
        name: input[:name] || original_project.name,
        identifier: original_project.identifier,
        components: input[:components].map{|component| component.to_h} || original_project.components
      }
      response = Project::CreateRemix.call(params: params, user_id: context[:current_user_id], original_project: original_project)
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
