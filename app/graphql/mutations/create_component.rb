# frozen_string_literal: true

module Mutations
  class CreateComponent < BaseMutation
    description 'A mutation to create a new component'
    input_object_class Types::CreateComponentInputType

    field :component, Types::ComponentType, description: 'The component that has been created'

    def resolve(**input)
      project = GlobalID.find("Z2lkOi8vYXBwL1Byb2plY3QvMmNmOTllOWItNGQzZS00MDQ2LWFjMWEtY2Q3MzMwNTFiNjA2")

      raise GraphQL::ExecutionError, 'Project not found' unless project

      unless context[:current_ability].can?(:update, project)
        raise GraphQL::ExecutionError,
              'You are not permitted to update this project'
      end

      newc = []
      input[:components].each {|component|
        newc.append(Component.new component.to_h)
      }

      return { project: } if project.update({components: project.components.append(newc)})

      raise GraphQL::ExecutionError, project.errors.full_messages.join(', ')
    end

    def ready?(**_args)
      print("here2")
      print("uid",context[:current_user_id])
      return true if context[:current_ability]&.can?(:create, Component, user_id: context[:current_user_id])

      raise GraphQL::ExecutionError, 'You are not permitted to create a component'
    end
  end
end
