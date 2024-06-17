# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

origins_array = ENV['ALLOWED_ORIGINS']&.split(',')&.map(&:strip) || []
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins_array
    resource '*', headers: :any, methods: %i[get post patch put delete], expose: ['Link']
  end
end
# Read more: https://github.com/cyu/rack-cors

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "example.com"
#
#     resource "*",
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end
