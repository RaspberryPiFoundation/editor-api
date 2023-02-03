# frozen_string_literal: true

origins_array = ENV['ALLOWED_ORIGINS']&.split(',')&.map(&:strip) || []

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins_array
    resource '*', headers: :any, methods: %i[get post patch put delete], expose: ['Link']
  end
end
