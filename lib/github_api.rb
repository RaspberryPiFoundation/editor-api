# frozen_string_literal: true

require 'graphql/client/http'

module GithubApi
  GITHUB_AUTH_TOKEN = ENV.fetch('GITHUB_AUTH_TOKEN', nil)
  URL = 'https://api.github.com/graphql'
  SCHEMA_FILENAME = Rails.root.join('db/github_graphql_schema.json').to_s

  HttpAdapter = GraphQL::Client::HTTP.new(URL) do
    def headers(_context)
      return {} unless GITHUB_AUTH_TOKEN

      { 'Authorization' => "Bearer #{GITHUB_AUTH_TOKEN}" }
    end
  end

  SCHEMA_SOURCE = if File.exist? SCHEMA_FILENAME
                     SCHEMA_FILENAME
                  else
                     self::HttpAdapter
                   end

  Schema = GraphQL::Client.load_schema(SCHEMA_SOURCE)
  Client = GraphQL::Client.new(schema: Schema, execute: HttpAdapter)
end
