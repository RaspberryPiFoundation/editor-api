# frozen_string_literal: true

module Mutations
  class DeleteProject < BaseMutation
    description 'A mutation to delete an existing project'

    argument :id, String, required: true, description: 'The ID of the project to delete'

    field :id, String, 'The ID of the project that has been deleted'

    def resolve(**input)
      project = GlobalID.find(input[:id])

      raise EditorApiError::NotFound, 'Project not found' unless project

      unless context[:current_ability].can?(:destroy, project)
        raise EditorApiError::Forbidden, 'You are not permitted to delete that project'
      end

      return { id: project.id } if project.destroy

      raise GraphQL::ExecutionError, "Deletion failed for project #{project.identifier}"
    end

    def ready?(...)
      unless context[:current_user_id]
        raise EditorApiError::Unauthorized,
              'You must be authenticated to delete a project'
      end

      return true if context[:current_ability]&.can?(:destroy, Project, user_id: context[:current_user_id])

      raise EditorApiError::Forbidden, 'You are not permitted to delete projects'
    end
  end
end
