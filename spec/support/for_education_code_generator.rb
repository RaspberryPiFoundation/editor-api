# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    puts "ForEducationCodeGenerator randomized with seed #{config.seed}"
    ForEducationCodeGenerator.random = Random.new(config.seed)
  end
end
