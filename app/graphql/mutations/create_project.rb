# frozen_string_literal: true

module Mutations
  class CreateProject < BaseMutation
    description 'A mutation to create a new project'

    field :project, Types::ProjectType, description: 'The project that has been created'

    argument :components, [Types::ComponentInputType], required: false, description: 'Any project components'
    argument :name, String, required: false, description: 'The name of the project'
    argument :project_type, String, required: false, description: 'The type of project, e.g. python, html'
    argument :remixed_from_id, ID, required: false,
                                   description: 'The ID of the project this project has been remixed from'

    def resolve(**input)
      project_hash = input.merge(user_id: context[:current_user_id],
                                 components: input[:components].map(&:to_h))

      response = Project::Create.call(project_hash:)
      raise GraphQL::ExecutionError, response[:error] unless response.success?

      { project: response[:project] }
    end

    def ready?(**_args)
      return true if context[:current_ability]&.can?(:create, Project, user_id: context[:current_user_id])

      raise GraphQL::ExecutionError, 'You are not permitted to create a project'
    end
  end
end
