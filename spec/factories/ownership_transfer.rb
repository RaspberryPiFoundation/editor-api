# frozen_string_literal: true

FactoryBot.define do
  factory :ownership_transfer do
    email_address { 'new-owner@example.com' }
    school factory: :verified_school
  end
end
