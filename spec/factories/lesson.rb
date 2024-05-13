# frozen_string_literal: true

FactoryBot.define do
  factory :lesson do
    user_id { SecureRandom.uuid }
    sequence(:name) { |n| "Lesson #{n}" }
    visibility { 'private' }
  end

  factory :lesson_with_school, parent: :lesson do
    school

    after(:create) do |lesson, _context|
      create(:teacher_role, school: lesson.school, user_id: lesson.user_id)
    end
  end
end
