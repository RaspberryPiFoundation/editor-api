# frozen_string_literal: true

require 'github_api'
require 'graphql/client/log_subscriber'

Rails.application.configure do
  config.github_api = ActiveSupport::OrderedOptions.new
  config.github_api.client = GithubApi::Client

  GraphQL::Client::LogSubscriber.attach_to :github_api
end
