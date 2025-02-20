# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    # teacher_ids { [SecureRandom.uuid] }
    sequence(:name) { |n| "Class #{n}" }

    transient do
      teacher_ids {[SecureRandom.uuid]}
    end

    after(:create) do |school_class, evaluator|
      class_teachers = evaluator.teacher_ids.map do |teacher_id|
        create(:class_teacher, school_class:, teacher_id:)
      end
      school_class.update!(class_teachers:)
    end
  end
end
