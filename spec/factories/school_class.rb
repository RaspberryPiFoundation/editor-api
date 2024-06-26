# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    teacher_id { SecureRandom.uuid }
    sequence(:name) { |n| "Class #{n}" }
  end
end
