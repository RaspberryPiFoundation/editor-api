# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { Faker::Name.name }
    email { Faker::Internet.email }
    organisations { {} }

    factory :admin_user do
      organisations { {} }
    end

    skip_create
  end
end
