module Mutations
  class CreateProject < BaseMutation
    field :project, Types::ProjectType, null: false
    field :errors, [String], null: false

    argument :project, Types::ProjectInputType, required: true

    def resolve(project:)
      params = project.to_h.merge(user_id: context[:current_user_id])
      { project: Project.create(**params) }
    end
  end
end
