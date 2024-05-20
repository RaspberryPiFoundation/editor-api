# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { User::TEACHER_ID } # Matches users.json.
    sequence(:name) { |n| "Lesson #{n}" }
    visibility { 'private' }
  end
end
