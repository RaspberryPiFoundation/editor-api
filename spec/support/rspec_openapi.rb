# frozen_string_literal: true

require 'rspec/openapi'

# Document the Authorization header on every operation that actually sends one,
# derived from the request specs themselves rather than annotated per spec.
RSpec::OpenAPI.request_headers = %w[Authorization]

# Response bodies balloon the spec with long example payloads. Strip only the
# response-side examples; request/query examples stay, since they're short and
# show valid input shapes.
RSpec::OpenAPI.post_process_hook = lambda do |_path, _records, spec|
  %i[example examples].each do |key|
    RSpec::OpenAPI::HashHelper.matched_paths(spec, "paths.*.*.responses.*.content.*.#{key}").each do |key_parts|
      spec.dig(*key_parts[0..-2])&.delete(key_parts.last)
    end
  end
end
