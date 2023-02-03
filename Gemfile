# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.1.0'

gem 'aws-sdk-s3', require: false
gem 'bootsnap', require: false
gem 'cancancan', '~> 3.3'
gem 'faraday'
gem 'github_webhook', '~> 1.4'
gem 'importmap-rails'
gem 'jbuilder'
gem 'kaminari'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.6'
gem 'rack-cors'
gem 'rails', '~> 7.0.0'
gem 'sentry-rails', '~> 5.5.0'

group :development, :test do
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
end

group :test do
  gem 'shoulda-matchers', '~> 5.0'
  gem 'webmock'
end
