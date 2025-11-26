# frozen_string_literal: true

# Allow Symbol class in YAML safe_load for OpenAPI specs
# This is needed because some YAML libraries may serialize Ruby symbols
# and we need to be able to load them in the API documentation
Rails.application.config.to_prepare do
  Psych.add_permitted_class(Symbol) if defined?(Psych) && Psych.respond_to?(:add_permitted_class)
end
