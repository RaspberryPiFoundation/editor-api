# frozen_string_literal: true

FactoryBot.define do
  factory :user_job do
    good_job_batch_id { nil }
    user_id { SecureRandom.uuid }
  end
end
