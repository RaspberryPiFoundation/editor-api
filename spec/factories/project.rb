# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    user_id { SecureRandom.uuid }
    name { Faker::Book.title }
    identifier { "#{Faker::Verb.base}-#{Faker::Verb.base}-#{Faker::Verb.base}" }
    project_type { 'python' }
    locale { %w[en es-LA fr-FR].sample }

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

    trait :with_attached_image do
      after(:build) do |object|
        object.images.attach(io: Rails.root.join('spec/fixtures/files/test_image_1.png').open,
                             filename: 'test_image',
                             content_type: 'image/png')
      end
    end
  end
end
