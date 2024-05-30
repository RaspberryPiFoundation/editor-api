# frozen_string_literal: true

FactoryBot.define do
  factory :role, aliases: [:owner_role] do
    school
    user_id { SecureRandom.uuid }
    role    { :owner }
  end

  factory :teacher_role, parent: :role do
    role { :teacher }
  end

  factory :student_role, parent: :role do
    role { :student }
  end
end
