# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    organisation_id { '12345678-1234-1234-1234-123456789abc' }
    owner_id { '00000000-0000-0000-0000-000000000000' }
    sequence(:name) { |n| "School #{n}" }
    address_line_1 { 'Address Line 1' }
    municipality { 'Greater London' }
    country_code { 'GB' }
  end
end
