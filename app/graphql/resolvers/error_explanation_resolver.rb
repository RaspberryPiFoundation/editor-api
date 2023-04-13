# frozen_string_literal: true
require 'openai'

module Resolvers
  class ErrorExplanationResolver

    def self.get_error_explanation(error:, code:)
      client = OpenAI::Client.new

      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {role: "system", content: "You are a kind pirate talking to a five year old child."},
            {role: "user", content: "Explain the error \"#{error}\" in the following python code: \"#{code}\""}
          ],
          temperature: 0.5
        })

      {message: response.dig("choices", 0, "message", "content")}
    end
  end
end
