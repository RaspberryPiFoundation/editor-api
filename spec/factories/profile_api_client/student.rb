# frozen_string_literal: true

FactoryBot.define do
  factory :profile_api_client_student, class: 'ProfileApiClient::Student' do
    id { SecureRandom.uuid }
    schoolId { SecureRandom.uuid }
    name { Faker::Name.name }
    username { Faker::Internet.username }
    email { Faker::Internet.email }

    # rubocop:disable Naming/VariableNumber
    createdAt { Time.current.to_fs(:iso8601) }
    updatedAt { Time.current.to_fs(:iso8601) }
    discardedAt { nil }
    # rubocop:enable Naming/VariableNumber

    initialize_with { ProfileApiClient::Student.new(**attributes) }

    trait :sso do
      name { Faker::Name.name }
      username { nil } # SSO students have no username
      email { Faker::Internet.email } # but do have email
    end

    trait :regular do
      name { Faker::Name.name }
      username { Faker::Internet.username } # Regular students have username
      email { Faker::Internet.email }
    end
  end
end
