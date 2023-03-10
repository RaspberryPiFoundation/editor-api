# frozen_string_literal: true

FactoryBot.define do
  factory :word do
    word { Faker::Verb.base }
  end
end
