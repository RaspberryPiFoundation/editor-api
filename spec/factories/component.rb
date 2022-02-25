# frozen_string_literal: true

FactoryBot.define do
  factory :component do
    name { Faker::Lorem.word }
    extension { 'py' }
    content { Faker::Lorem.paragraph(sentence_count: 2) }
  end
end
