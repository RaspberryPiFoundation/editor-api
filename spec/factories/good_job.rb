# frozen_string_literal: true

FactoryBot.define do
  factory :good_job, class: 'GoodJob::Job' do
    # Add necessary attributes here
    queue_name { 'default' }
    priority { 0 }
    serialized_params { {} }
    scheduled_at { Time.current }
    performed_at { nil }
    finished_at { nil }
    error { nil }
  end
end
