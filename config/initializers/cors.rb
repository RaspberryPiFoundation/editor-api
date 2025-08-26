# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
# Read more: https://github.com/cyu/rack-cors

require Rails.root.join('lib/origin_parser')

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # localhost and test domain origins
    origins(%r{https?://localhost([:0-9]*)$}) if Rails.env.local?

    standard_cors_options
  end

  allow do
    # environment-specific origins set through ALLOWED_ORIGINS env var
    # should only be necessary for staging / production environments (see above for local and test)
    origins OriginParser.parse_origins

    standard_cors_options
  end
end

def standard_cors_options
  resource '*', headers: :any, methods: %i[get post patch put delete], expose: ['Link']
end
