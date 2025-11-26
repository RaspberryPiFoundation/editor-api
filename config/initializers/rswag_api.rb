# frozen_string_literal: true

if defined?(Rswag::Api)
  Rswag::Api.configure do |c|
    # Specify a root folder where Swagger JSON files are located
    # This is used by the Swagger middleware to serve requests for API descriptions
    # NOTE: If you're using rswag-specs to generate Swagger, you'll also need to
    # ensure that it's configured to generate files in the same folder
    c.openapi_root = Rails.root.join('swagger').to_s

    # Inject a lambda function to alter the returned Swagger prior to serialization
    # The function will have access to the rack env for the current request
    # For example, you could leverage this to dynamically assign the "host" property
    #
    # c.swagger_filter = lambda { |swagger, env| swagger['host'] = env['HTTP_HOST'] }
  end

  # Monkey patch to allow Symbol class in YAML safe_load
  # This is needed because rspec-openapi may serialize Ruby symbols in the YAML
  module Rswag
    module Api
      class Middleware
        private

        def load_yaml(filename)
          YAML.safe_load_file(filename, permitted_classes: [Symbol, Date, Time])
        end
      end
    end
  end
end
