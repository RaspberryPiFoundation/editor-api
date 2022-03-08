# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    user_id { SecureRandom.uuid }
    name { Faker::Book.title }
    identifier { "#{Faker::Verb.base}-#{Faker::Verb.base}-#{Faker::Verb.base}" }
    project_type { 'python' }

    trait :with_components do
      transient do
        component_count { 1 }
      end

      after(:create) do |object, evaluator|
        object.components << FactoryBot.create_list(:component,
                                                   evaluator.component_count,
                                                   project: object)
      end
    end

    trait :with_default_component do
      after(:create) do |object|
        object.components << FactoryBot.create(:default_python_component, project: object)
      end
    end
  end
end
