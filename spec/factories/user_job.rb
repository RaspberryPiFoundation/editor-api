# frozen_string_literal: true

FactoryBot.define do
  factory :user_job do
    association :good_job, factory: :good_job
    user_id { SecureRandom.uuid }
  end
end
