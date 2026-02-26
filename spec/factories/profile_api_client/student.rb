# frozen_string_literal: true

FactoryBot.define do
  factory :profile_api_client_student, class: 'ProfileApiClient::Student' do
    id { SecureRandom.uuid }
    schoolId { SecureRandom.uuid }
    name { Faker::Name.name }
    username { Faker::Internet.username }
    email { Faker::Internet.email }
    ssoProviders { [] } # standard students have no SSO providers

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
      ssoProviders { ['google'] } # SSO students have SSO providers
    end
  end
end
