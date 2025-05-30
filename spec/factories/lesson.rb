# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    sequence(:name) { |n| "Lesson #{n}" }
    description { 'Description' }
    visibility { 'teachers' }
    project { create(:project, user_id:, name:, school: school || school_class&.school) }

    trait :with_project_components do
      transient do
        component_count { 1 }
      end

      after(:create) do |object, evaluator|
        object.project.components << FactoryBot.create_list(:component,
                                                            evaluator.component_count,
                                                            project: object.project)
      end
    end

    trait :with_project_image do
      after(:build) do |object|
        object.project.images.attach(io: Rails.root.join('spec/fixtures/files/test_image_1.png').open,
                                     filename: 'test_image',
                                     content_type: 'image/png')
      end
    end
  end
end
