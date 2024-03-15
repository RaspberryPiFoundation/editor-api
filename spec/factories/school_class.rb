# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    school
    teacher_id { '11111111-1111-1111-1111-111111111111' } # Matches users.json.
    sequence(:name) { |n| "Class #{n}" }
  end
end
