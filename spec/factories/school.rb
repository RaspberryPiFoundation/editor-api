# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    organisation_id { SecureRandom.uuid }
    sequence(:name) { |n| "School #{n}" }
  end
end
