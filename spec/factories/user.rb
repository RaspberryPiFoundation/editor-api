# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    name { Faker::Name.name }
    roles { nil }
    email { Faker::Internet.email }

    factory :admin_user do
      roles { 'editor-admin' }
    end

    skip_create
  end
end
