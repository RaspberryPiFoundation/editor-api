# frozen_string_literal: true

# rspec-openapi configuration
# This allows automatic OpenAPI spec generation from request specs
# Run with: OPENAPI=1 bundle exec rspec spec/requests/

if defined?(RSpec::OpenAPI)
  RSpec::OpenAPI.title = 'Editor API V1'
  RSpec::OpenAPI.application_version = 'v1'

  # Use info hash for additional metadata
  RSpec::OpenAPI.info = {
    version: 'v1',
    title: 'Editor API V1',
    description: 'REST and GraphQL APIs for Raspberry Pi Foundation Code Editor'
  }

  RSpec::OpenAPI.path = Rails.root.join('swagger/v1/swagger.yaml')

  RSpec::OpenAPI.comment = <<~COMMENT
    This OpenAPI specification is automatically generated from request specs.

    To regenerate:
      OPENAPI=1 bundle exec rspec spec/requests/

    Last generated: #{Time.current}
  COMMENT

  # Configure servers based on environment
  RSpec::OpenAPI.servers = [
    {
      url: ENV.fetch('HOST_URL', 'http://localhost:3009'),
      description: Rails.env.production? ? 'Production' : 'Development'
    }
  ]

  # Define security schemes
  RSpec::OpenAPI.security_schemes = {
    'bearer_auth' => {
      'type' => 'http',
      'scheme' => 'bearer',
      'description' => 'Hydra API token via Authorization: Bearer <token>'
    }
  }

  # Request headers to include in documentation
  RSpec::OpenAPI.request_headers = %w[
    Authorization
  ]

  # Response headers to exclude from documentation
  RSpec::OpenAPI.response_headers = []

  # Paths to ignore (e.g., internal/test endpoints)
  RSpec::OpenAPI.ignored_paths = [
    %r{^/admin},
    %r{^/test},
    %r{^/graphql}
  ]
end
