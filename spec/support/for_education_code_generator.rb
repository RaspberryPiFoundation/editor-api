# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    Rails.logger.debug { "ForEducationCodeGenerator randomized with seed #{config.seed}" }
    ForEducationCodeGenerator.random = Random.new(config.seed)
  end
end
