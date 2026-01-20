# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    name { "#{Faker::Educator.primary_school} #{Faker::Address.city}" }
    website { Faker::Internet.url }
    address_line_1 { Faker::Address.street_address }
    administrative_area { "#{Faker::Address.city}shire" }
    municipality { Faker::Address.city }
    postal_code { Faker::Address.postcode }
    country_code { 'GB' }
    sequence(:reference) { |n| format('%06d', 100_000 + n) }
    school_roll_number { nil }
    creator_id { SecureRandom.uuid }
    creator_agree_authority { true }
    creator_agree_terms_and_conditions { true }
    creator_agree_responsible_safeguarding { true }
  end

  factory :verified_school, parent: :school do
    verified_at { Time.current }
    code { ForEducationCodeGenerator.generate }
  end
end
