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

    trait :with_attached_images do
      after(:create) do |object|
        object.images.attach(fixture_file_upload(Rails.root.join('spec/fixtures/test_image_1.png'), 'image/png'))
      end
    end
  end
end
