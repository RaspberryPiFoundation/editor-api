# frozen_string_literal: true

FactoryBot.define do
  factory :class_student do
    school_class
    student_id { SecureRandom.uuid }
  end
end
