# frozen_string_literal: true

FactoryBot.define do
  factory :school_project do
    school_id { SecureRandom.uuid }
    project_id { SecureRandom.uuid }
  end
end
