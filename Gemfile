# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.2.0'

gem 'aws-sdk-s3', require: false
gem 'bootsnap', require: false
gem 'cancancan', '~> 3.3'
gem 'countries'
gem 'email_validator'
gem 'faraday'
gem 'github_webhook', '~> 1.4'
gem 'globalid'
gem 'good_job', '~> 3.12'
gem 'graphql'
gem 'graphql-client'
gem 'importmap-rails'
gem 'jbuilder'
gem 'kaminari'
gem 'open-uri'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.6'
gem 'rack-cors'
gem 'rails', '~> 7.0.0'
gem 'roo'
gem 'scout_apm'
gem 'sentry-rails', '~> 5.5.0'

group :development, :test do
  gem 'bullet'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
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

group :test do
  gem 'climate_control'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'webmock'
end
