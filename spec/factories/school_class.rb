# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    sequence(:name) { |n| "Class #{n}" }

    transient do
      teacher_ids { [SecureRandom.uuid] }
    end

    after(:build) do |school_class, evaluator|
      teachers = evaluator.teacher_ids.map do |teacher_id|
        build(:class_teacher, school_class:, teacher_id:)
      end
      school_class.teachers = teachers
    end
  end
end
