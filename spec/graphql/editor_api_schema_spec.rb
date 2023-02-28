# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApiSchema do
  it 'matches the dumped schema (rails graphql:dump_schema)' do
    # If this test fails, run the rake task "rails graphql:dump_schema" inside the docker container to regenerate the
    # schema file. Keep the schema in source control to make it easier to see any changes in pull requests.
    aggregate_failures do
      expect(described_class.to_definition).to eq(Rails.root.join('db/schema.graphql').read)
    end
  end
end
