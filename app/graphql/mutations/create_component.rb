# frozen_string_literal: true

module Mutations
  class CreateComponent < BaseMutation
    description 'A mutation to create a new component'
    input_object_class Types::CreateComponentInputType

    field :component, Types::ComponentType, description: 'The component that has been created'

    def resolve(**input)
      project = GlobalID.find(input[:project_id])

      raise GraphQL::ExecutionError, 'Project not found' unless project

      component = Component.new input
      component.project = project

      unless context[:current_ability].can?(:create, component)
        raise GraphQL::ExecutionError,
              'You are not permitted to update this component'
      end

      return { component: } if component.save

      raise GraphQL::ExecutionError, component.errors.full_messages.join(', ')
    end

    def ready?(**_args)
      if context[:current_ability]&.can?(:create, Component, Project.new(user_id: context[:current_user]&.id))
        return true
      end

      raise GraphQL::ExecutionError, 'You are not permitted to create a component'
    end
  end
end
