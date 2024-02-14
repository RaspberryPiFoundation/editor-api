# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { Faker::Name.name }
    roles { nil }
    email { Faker::Internet.email }

    skip_create
  end
end
