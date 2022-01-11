# frozen_string_literal: true

FactoryBot.define do
    factory :project do
        user_id { rand( 10 ** 10 ) }
        name { Faker::Book.title }
        identifier {Faker::Verb.base+'-'+Faker::Verb.base+'-'+Faker::Verb.base}
        project_type { %w[python, html].sample }
    end
end
