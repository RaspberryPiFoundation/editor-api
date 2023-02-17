# frozen_string_literal: true

module Types
  class ImageType < Types::BaseObject
    field :id, ID, null: false
    field :filename, String, null: false
    field :url, String
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
