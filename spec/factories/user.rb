# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }

    factory :admin_user do
      roles { 'editor-admin' }
    end

    factory :student do
      transient do
        school { nil }
      end

      after(:create) do |user, context|
        create(:student_role, user_id: user.id, school: context.school)
      end
    end

    factory :teacher do
      transient do
        school { nil }
      end

      after(:create) do |user, context|
        create(:teacher_role, user_id: user.id, school: context.school)
      end
    end

    skip_create
  end
end
