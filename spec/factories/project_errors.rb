# frozen_string_literal: true

FactoryBot.define do
  factory :project_error do
    error { Faker::Lorem.words(number: rand(2..10)).join(' ') }
  end
end
