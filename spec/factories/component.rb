# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    name { Faker::Lorem.word }
    extension { 'py' }
    default { false }
    content { Faker::Lorem.paragraph }
    project

    factory :default_python_component do
      name { 'main' }
      default { true }
    end
  end
end
