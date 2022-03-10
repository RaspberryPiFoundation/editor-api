# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    name { Faker::Lorem.word }
    extension { 'py' }
    sequence(:index) { |n| n }
    default { false }
    project

    factory :default_python_component do
      name { 'main' }
      index { 0 }
      default { true }
    end
  end
end
