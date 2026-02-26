# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    Rails.logger.debug { "Faker randomized with seed #{config.seed}" }
    Faker::Config.random = Random.new(config.seed)
  end
end
