# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    organisation_id { SecureRandom.uuid }
    owner_id { SecureRandom.uuid }
    sequence(:name) { |n| "School #{n}" }
    address_line_1 { 'Address Line 1' }
    municipality { 'Greater London' }
    country_code { 'GB' }
  end
end
