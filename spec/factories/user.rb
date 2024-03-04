# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    organisations { {} }

    skip_create
  end
end
