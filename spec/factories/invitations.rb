# frozen_string_literal: true

FactoryBot.define do
  factory :invitation do
    email_address { 'teacher@example.com' }
    school factory: :school, verified_at: Time.zone.now
  end
end
