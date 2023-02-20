# frozen_string_literal: true

require 'graphql/client/http'

module GitHub
  GITHUB_AUTH_TOKEN = ENV.fetch('GITHUB_ACCESS_TOKEN', nil)
  URL = 'https://api.github.com/graphql'
  HttpAdapter = GraphQL::Client::HTTP.new(URL) do
    def headers(_context)
      {
        'Authorization' => "Bearer #{GITHUB_AUTH_TOKEN}",
        'User-Agent' => 'Ruby'
      }
    end
  end
  Schema = GraphQL::Client.load_schema(HttpAdapter)
  Client = GraphQL::Client.new(schema: Schema, execute: HttpAdapter)
end
