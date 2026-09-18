# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    username { nil }
    sso_providers { [] }
    sub { id }

    factory :admin_user do
      roles { 'editor-admin' }
    end

    factory :experience_cs_admin_user do
      roles { 'experience-cs-admin' }
    end

    factory :student do
      transient do
        school { nil }
      end

      email { nil }
      username { Faker::Internet.username }
      sso_providers { [] } # standard students have no SSO providers
      sub { "student:#{id}" }
      school_id { school&.id || create(:school).id }

      trait :sso do
        email { Faker::Internet.email }
        username { nil }
        sso_providers { ['google'] } # SSO students have SSO providers
      end

      after(:create) do |user|
        create(:student_role, user_id: user.id, school_id: user.school_id)
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

    factory :owner do
      transient do
        school { nil }
      end

      after(:create) do |user, context|
        create(:owner_role, user_id: user.id, school: context.school)
      end
    end

    skip_create
  end
end
