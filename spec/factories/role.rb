# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    school
    user_id { '00000000-0000-0000-0000-000000000000' }
    role    { 0 }
  end

  factory :owner_role, parent: :role do
    role { 'owner' }
  end
end
