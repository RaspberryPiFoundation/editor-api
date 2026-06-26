# frozen_string_literal: true

FactoryBot.define do
  factory :school_email_domain do
    school
    sequence(:domain) { |n| "domain#{n}.example.edu" }
  end
end
