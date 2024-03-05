# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { '11111111-1111-1111-1111-111111111111' } # Matches users.json.
    sequence(:name) { |n| "Lesson #{n}" }
    visibility { 'private' }
  end
end
