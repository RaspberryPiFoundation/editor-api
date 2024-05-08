# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    sequence(:name) { |n| "School #{n}" }
    website { 'http://www.example.com' }
    address_line_1 { 'Address Line 1' }
    municipality { 'Greater London' }
    country_code { 'GB' }
  end
end
