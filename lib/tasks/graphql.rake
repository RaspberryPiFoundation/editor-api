# frozen_string_literal: true

require 'github_api'

namespace :graphql do
  desc 'update db/schema.graphql to match the current EditorApiSchema to keep track of schema changes'
  task dump_schema: :environment do
    # see https://rmosolgo.github.io/ruby/graphql/2017/03/16/tracking-schema-changes-with-graphql-ruby

    # Get a string containing the definition in GraphQL IDL:
    schema_definition = EditorApiSchema.to_definition
    # Choose a place to write the schema dump:
    schema_path = 'db/schema.graphql'
    # Write the schema dump to that file:
    Rails.root.join(schema_path).write(schema_definition)
    puts "Updated Editor API GraphQL schema at #{schema_path}"
  end

  desc 'update db/github_schema.graphql to match current schema'
  task dump_github_schema: :environment do
    GraphQL::Client.dump_schema(GithubApi::HttpAdapter, GithubApi::SCHEMA_FILENAME)
  end
end
