# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    sequence(:name) { |n| "Lesson #{n}" }
    description { 'Description' }
    visibility { 'teachers' }
    project { create(:project, user_id: user_id) }
  end
end
