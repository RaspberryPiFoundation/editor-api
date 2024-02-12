# frozen_string_literal: true

FactoryBot.define do
  factory :class_member do
    school_class
    student_id { '22222222-2222-2222-2222-222222222222' } # Matches users.json.
  end
end
