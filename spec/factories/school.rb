# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    sequence(:name) { |n| "School #{n}" }
    website { 'http://www.example.com' }
    address_line_1 { 'Address Line 1' }
    municipality { 'Greater London' }
    country_code { 'GB' }
    creator_id { SecureRandom.uuid }
    creator_agree_authority { true }
    creator_agree_terms_and_conditions { true }
  end

  factory :verified_school, parent: :school do
    verified_at { Time.current }
    code { SchoolCodeGenerator.generate }
  end
end
