# frozen_string_literal: true

FactoryBot.define do
    factory :project do
        user_id { rand( 10 ** 10 ) }
        name { Faker::Book.title }
        identifier { Faker::Verb.base(number: 3).join('-') }
        project_type { %w[python, html].sample }
    end
end
