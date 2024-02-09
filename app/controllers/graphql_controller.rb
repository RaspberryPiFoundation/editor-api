# frozen_string_literal: true

class GraphqlController < ApiController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    result = EditorApiSchema.execute(query, variables:, context:, operation_name:)
    render json: result
  end

  private

  def query
    params[:query]
  end

  def operation_name
    params[:operationName]
  end

  def context
    @context ||= { current_user:, current_ability: Ability.new(current_user), remix_origin: request.origin }
  end

  # Handle variables in form data, JSON body, or a blank value
  def variables
    variables_param = params[:variables]

    return {} if variables_param.blank?

    case variables_param
    when String
      JSON.parse(variables_param) || {}
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end
end
