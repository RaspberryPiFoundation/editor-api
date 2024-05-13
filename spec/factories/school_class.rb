# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    school
    teacher_id { SecureRandom.uuid }
    sequence(:name) { |n| "Class #{n}" }

    after(:create) do |school_class, _context|
      create(:teacher_role, school: school_class.school, user_id: school_class.teacher_id)
    end
  end
end
