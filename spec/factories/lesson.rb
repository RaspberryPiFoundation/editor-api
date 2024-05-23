# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    sequence(:name) { |n| "Lesson #{n}" }
    visibility { 'private' }
  end
end
