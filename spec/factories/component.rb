# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    name { Faker::Lorem.word }
    extension { 'py' }
    sequence (:index) { |n| n }
  end
end
