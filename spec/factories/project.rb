# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    user_id { SecureRandom.uuid }
    name { Faker::Book.title }
    identifier { "#{Faker::Verb.base}-#{Faker::Verb.base}-#{Faker::Verb.base}" }
    project_type { 'python' }

    trait :with_components do
      after(:create) do |object|
        object.components = FactoryBot.create_list(:component, 2, project: object)
      end
    end
  end
end
