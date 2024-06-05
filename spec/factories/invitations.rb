# frozen_string_literal: true

FactoryBot.define do
  factory :invitation do
    email_address { 'teacher@example.com' }
    school
  end
end
