# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    association :school, factory: :school
    association :school_class, factory: :school_class
    sequence(:name) { |n| "Lesson #{n}" }
    description { 'Description' }
    visibility { 'private' }
  end
end
