# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.2.0'

gem 'administrate', '~> 0.20.1'
gem 'administrate-field-active_storage'
gem 'aws-sdk-s3', require: false
gem 'bootsnap', require: false
gem 'cancancan', '~> 3.3'
gem 'countries'
gem 'email_validator'
gem 'faker'
gem 'faraday'
gem 'github_webhook', '~> 1.4'
gem 'globalid'
gem 'good_job', '~> 4.3'
gem 'graphql'
gem 'graphql-client'
gem 'image_processing'
gem 'importmap-rails'
gem 'jbuilder'
gem 'kaminari'
gem 'omniauth-rails_csrf_protection', '~> 1.0.1'
gem 'omniauth-rpi',
    github: 'RaspberryPiFoundation/omniauth-rpi',
    tag: 'v1.3.1'
gem 'open-uri'
gem 'paper_trail'
gem 'pg', '~> 1.1'
gem 'postmark-rails'
gem 'puma', '~> 6'
gem 'rack-cors'
gem 'rails', '~> 7.1'
gem 'scout_apm'
gem 'sentry-rails'

group :development, :test do
  gem 'bullet'
  gem 'debug'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'graphiql-rails'
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-graphql', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
end

group :development do
  gem 'awesome_print'
  gem 'rails-erd'
  gem 'ruby-lsp-rails'
  gem 'ruby-lsp-rspec'
end

group :test do
  gem 'capybara'
  gem 'climate_control'
  gem 'database_cleaner-active_record'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'webdrivers'
  gem 'webmock'
end
