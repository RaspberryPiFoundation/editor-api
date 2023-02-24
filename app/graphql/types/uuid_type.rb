# frozen_string_literal: true

module Types
  class UuidType < GraphQL::Types::String
    description 'A globally unique ID'
  end
end
