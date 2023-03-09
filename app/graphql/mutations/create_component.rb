# frozen_string_literal: true

module Mutations
  class CreateComponent < BaseMutation
    description 'A mutation to create a new component'
    input_object_class Types::CreateComponentInputType

    field :component, Types::ComponentType, description: 'The component that has been created'

    def resolve(**input)
      #project_hash = input.merge(user_id: context[:current_user_id],
      #                           components: input[:components]&.map(&:to_h))

      #print("here", input)
      #project = GlobalID.find(input[:identifier])
      #response = Component.new(project_id: 'atom-spout-enter', name: 'test1', extension: 'py')
      #raise GraphQL::ExecutionError, response[:error] unless response.success?

      print("--------")
      print(input)
    
      print("------------")

      project = GlobalID.find("Z2lkOi8vYXBwL1Byb2plY3QvMmNmOTllOWItNGQzZS00MDQ2LWFjMWEtY2Q3MzMwNTFiNjA2")
    

      raise GraphQL::ExecutionError, 'Project not found' unless project

      unless context[:current_ability].can?(:update, project)
        raise GraphQL::ExecutionError,
              'You are not permitted to update this project'
      end

      #return { project: } if project.update(input[:components])
      t = {components: project.components.append([Component.new(name: 'main2', extension: 'py')])}
      return { project: } if project.update(t)

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
