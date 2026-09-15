# frozen_string_literal: true

FactoryBot.define do
  factory :ownership_transfer do
    school
    email_address { Faker::Internet.email }
    nominated_user_id { SecureRandom.uuid }
    requested_by_user_id { SecureRandom.uuid }
    status { 'pre_pending' }
  end
end
