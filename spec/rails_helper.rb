# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails' do
  enable_coverage :branch
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
ENV['BYPASS_AUTH'] = nil # Ensure we don't bypass auth in tests

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'webmock/rspec'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = Rails.root.join('spec/fixtures')

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.define_derived_metadata(file_path: %r{/spec/graphql/(queries|mutations)}) do |metadata|
    metadata[:type] = :graphql_query
  end

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # To be able to use build(:object) instead of FactoryBot.build(:object):
  config.include FactoryBot::Syntax::Methods
  config.include ValidGraphqlQueryMatcher, type: :graphql_query
  config.include GraphqlQueryHelpers, type: :graphql_query

  config.include PhraseIdentifierMock
  config.include ProfileApiMock
  config.include UserProfileMock

  config.include SignInStubs, type: :request
  config.include SignInStubs, type: :system

  if Bullet.enable?
    config.before { Bullet.start_request }
    config.after  { Bullet.end_request }
  end

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:suite) do
    db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
    puts "Running tests in environment: #{Rails.env}"
    puts "Running tests against the database: #{db_config.database}"
  end

  config.before(:each, js: true, type: :system) do
    # We need to allow net connect at this stage to allow WebDrivers to update
    # or Capybara to talk to selenium etc.
    WebMock.allow_net_connect!

    # Ensure we update the driver here, while we can connect to the network
    Webdrivers::Geckodriver.update
    driven_by :selenium_headless, using: :firefox

    # Need to set the hostname, otherwise it defaults to www.example.com.
    default_url_options[:host] = Capybara.server_host

    WebMock.disable_net_connect!(allow_localhost: true, allow: Capybara.server_host)
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
