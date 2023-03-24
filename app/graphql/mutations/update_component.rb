# frozen_string_literal: true

module Mutations
  class UpdateComponent < BaseMutation
    description 'A mutation to update an existing component'

    input_object_class Types::UpdateComponentInputType

    field :component, Types::ComponentType, description: 'The component that has been updated'

    def resolve(**input)
      component = GlobalID.find(input[:id])
      raise GraphQL::ExecutionError, 'Component not found' unless component

      unless context[:current_ability].can?(:update, component)
        raise GraphQL::ExecutionError,
              'You are not permitted to update this component'
      end

      return { component: } if component.update(input.slice(:content, :name, :extension, :default))

      raise GraphQL::ExecutionError, component.errors.full_messages.join(', ')
    end

    def ready?(**_args)
      return true if context[:current_ability]&.can?(:update, Component, user_id: context[:current_user_id])

      raise GraphQL::ExecutionError, 'You are not permitted to update a component'
    end
  end
end
