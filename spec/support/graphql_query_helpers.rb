# frozen_string_literal: true

module GraphqlQueryHelpers
  def execute_query(query:, context: graphql_context, variables: {})
    EditorApiSchema.execute(query:, context:, variables:).as_json
  end

  def graphql_context
    if defined? current_user_id
      { current_user_id:, current_ability: Ability.new(current_user_id) }
    else
      { current_user_id: nil, current_ability: Ability.new(nil) }
    end
  end
end
