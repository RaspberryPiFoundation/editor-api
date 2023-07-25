# frozen_string_literal: true

module Types
  class ErrorExplanationType < Types::BaseObject
    description 'Explain an error message for given python code using ChatGPT'
    field :message, String, null: false, description: 'Generated explanation of the error'

  end
end
