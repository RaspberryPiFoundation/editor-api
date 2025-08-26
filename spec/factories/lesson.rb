# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    sequence(:name) { |n| "Lesson #{n}" }
    description { 'Description' }
    visibility { 'teachers' }
    transient do
      project_name { name }
    end

    association :project, factory: :project

    after(:build) do |lesson, evaluator|
      lesson.project.user_id = lesson.user_id
      lesson.project.name = evaluator.project_name
      lesson.project.identifier = "#{lesson.name.parameterize}-#{lesson.user_id}"
    end

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
