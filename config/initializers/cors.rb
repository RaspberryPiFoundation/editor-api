# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
# Read more: https://github.com/cyu/rack-cors

require Rails.root.join('lib/origin_parser')

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # localhost and test domains
    if Rails.env.development?
      origins(%r{https?://localhost([:0-9]*)$})
    elsif Rails.env.test?
      origins(%r{https?://localhost([:0-9]*)$}, %r{https?://www\.example\.com$})
    end

    standard_cors_options
  end

  allow do
    origins OriginParser.parse_origins

    standard_cors_options
  end
end

def standard_cors_options
  resource '*', headers: :any, methods: %i[get post patch put delete], expose: ['Link']
end
