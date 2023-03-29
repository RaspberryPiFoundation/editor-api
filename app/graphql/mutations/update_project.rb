# frozen_string_literal: true

module Mutations
  class UpdateProject < BaseMutation
    description 'A mutation to update an existing project'

    input_object_class Types::UpdateProjectInputType

    field :project, Types::ProjectType, description: 'The project that has been updated'

    def resolve(**input)
      project = GlobalID.find(input[:id])
      raise EditorApiError::NotFound, 'Project not found' unless project

      unless context[:current_ability].can?(:update, project)
        raise EditorApiError::Forbidden,
              'You are not permitted to update this project'
      end

      return { project: } if project.update(input.slice(:project_type, :name))

      raise GraphQL::ExecutionError, project.errors.full_messages.join(', ')
    end

    def ready?(...)
      unless context[:current_user_id]
        raise EditorApiError::Unauthorized,
              'You must be authenticated to update a project'
      end

      return true if context[:current_ability]&.can?(:update, Project, user_id: context[:current_user_id])

      raise EditorApiError::Forbidden, 'You are not permitted to update a project'
    end
  end
end
