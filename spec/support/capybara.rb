# frozen_string_literal: true

require 'capybara/rspec'

Capybara.configure do |config|
  config.server = :puma, { Silent: true }
  config.always_include_port = true
  # This is where the server will listen.  We use this same `server_host` when
  # making requests in our browser etc.
  config.server_host = ENV.fetch('HOSTNAME')
end
