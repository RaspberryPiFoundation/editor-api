# frozen_string_literal: true

# rubocop:disable GraphQL/ObjectDescription
class EditorApiError
  class Base < GraphQL::ExecutionError
    def initialize(*, **args)
      args[:extensions] ||= {}
      args[:extensions].merge!(code:)

      super(*, **args)
    end

    def code
      self.class::CODE
    end
  end

  # These are modelled on Apollo GraphQL server
  # https://www.apollographql.com/docs/apollo-server/data/errors/#built-in-error-codes

  CODES = [
    'GRAPHQL_PARSE_FAILED', # The GraphQL operation string contains a syntax error.
    'GRAPHQL_VALIDATION_FAILED', # The GraphQL operation is not valid against the server's schema.
    'BAD_USER_INPUT', # The GraphQL operation includes an invalid value for a field argument.
    'BAD_REQUEST', # An error occurred before your server could attempt to parse the given GraphQL operation.
    'UNAUTHORIZED', # User needs to be authorized before this request can be fulfilled
    'FORBIDDEN', # User is not permitted to make the request
    'NOT_FOUND', # The object is not found
    'INTERNAL_SERVER_ERROR' # Something else..
  ].freeze

  CODES.each do |code|
    klass = Class.new(Base) do
      const_set :CODE, code
    end

    const_set code.downcase.camelize, klass
  end
end
# rubocop:enable GraphQL/ObjectDescription
