# frozen_string_literal: true

FactoryBot.define do
  factory :class_member do
    school_class
    student_id { SecureRandom.uuid }
  end
end
