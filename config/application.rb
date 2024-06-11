# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require "rails/test_unit/railtie"
require_relative '../lib/corp_middleware'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_support.cache_format_version = 7.1

    config.add_autoload_paths_to_load_path = false

    config.autoload_paths << "#{root}/lib"
    config.autoload_paths << "#{root}/lib/concepts"
    Rails.autoloaders.main.collapse('lib/concepts/*/operations')
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec
    end

    config.assets.css_compressor = nil

    config.active_job.queue_adapter = :good_job

    config.to_prepare do
      Administrate::ApplicationController.helper App::Application.helpers
    end

    config.api_only = false

    config.middleware.insert_before 0, CORPMiddleware
    config.generators.system_tests = nil
  end
end
