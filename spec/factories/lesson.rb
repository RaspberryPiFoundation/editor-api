# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    sequence(:name) { |n| "Lesson #{n}" }
    description { 'Description' }
    visibility { 'private' }
    project { create(:project) }
  end
end
