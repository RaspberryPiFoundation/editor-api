# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    user_id { SecureRandom.uuid }
    name { Faker::Book.title }
    identifier { "#{Faker::Verb.base}-#{Faker::Verb.base}-#{Faker::Verb.base}" }
    project_type { Project::Types::PYTHON }
    locale { %w[en es-LA fr-FR].sample }

    transient do
      # school { nil }
      # school_id { nil }
      finished { nil }
    end

    after(:create) do |project, evaluator|
      if evaluator.finished.present?
        project.school_project.finished = evaluator.finished
        project.school_project.save!
      end
    end

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

    trait :with_attached_video do
      after(:build) do |object|
        object.videos.attach(io: Rails.root.join('spec/fixtures/files/test_video_1.mp4').open,
                             filename: 'test_video',
                             content_type: 'video/mp4')
      end
    end

    trait :with_attached_audio do
      after(:build) do |object|
        object.audio.attach(io: Rails.root.join('spec/fixtures/files/test_audio_1.mp3').open,
                            filename: 'test_audio',
                            content_type: 'audio/mp3')
      end
    end

    trait :with_instructions do
      instructions { Faker::Lorem.paragraph }
      school { create(:school) }
    end
  end
end
