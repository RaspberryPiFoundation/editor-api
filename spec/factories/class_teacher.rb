# frozen_string_literal: true

FactoryBot.define do
  factory :class_teacher do
    school_class
    teacher_id { SecureRandom.uuid }
  end
end
