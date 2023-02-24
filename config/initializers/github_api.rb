# frozen_string_literal: true

require 'github_api'
require 'graphql/client/log_subscriber'

Rails.application.configure do
  config.git_hub_api = ActiveSupport::OrderedOptions.new
  config.git_hub_api.client = GithubApi::Client

  GraphQL::Client::LogSubscriber.attach_to :git_hub_api
end
