# frozen_string_literal: true

module ValidGraphqlQueryMatcher
  extend RSpec::Matchers::DSL

  matcher :be_a_valid_graphql_query do
    match do |actual|
      @graphql_errs = EditorApiSchema.validate(actual)
      @graphql_errs.empty?
    end

    failure_message do |actual|
      msg = @graphql_errs.map do |error|
        path = error.path.join(' -> ')
        "* #{path}: #{error.message}"
      end.join("\n")
      "expected #{actual.inspect} to be a valid graphql query:\n#{msg}"
    end
  end
end
