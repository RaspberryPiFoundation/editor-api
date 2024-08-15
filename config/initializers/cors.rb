# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# fetch origins from the environment, these can be literal strings or regexes
origins_array = ENV['ALLOWED_ORIGINS']&.split(',')&.map do |origin|
  stripped_origin = origin.strip
  if stripped_origin.start_with?('/') && stripped_origin.end_with?('/')
    # convert to Regexp if the origin is wrapped in forward slashes eg. /https?:\/\/localhost(:[0-9]*)?$/
    Regexp.new(stripped_origin[1..-2])
  else
    stripped_origin
  end
end || []

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
    # fetch allowed origins from the environment
    origins origins_array

    standard_cors_options
  end
end

def standard_cors_options
  resource '*', headers: :any, methods: %i[get post patch put delete], expose: ['Link']
end
