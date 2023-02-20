# frozen_string_literal: true

module Types
  class ImageType < Types::BaseObject
    description 'An image'

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'The time the image was created'
    field :filename, String, null: false, description: 'The original filename of the image'
    field :url, String, description: 'The URL where the image can be downloaded from'
  end
end
