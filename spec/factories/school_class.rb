# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    school
    teacher_id { User::TEACHER_ID } # Matches users.json.
    sequence(:name) { |n| "Class #{n}" }
  end
end
