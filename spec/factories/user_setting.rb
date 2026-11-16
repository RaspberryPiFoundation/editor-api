# frozen_string_literal: true

FactoryBot.define do
  factory :user_setting do
    user_id { SecureRandom.uuid }
    settings { {} }
  end
end
