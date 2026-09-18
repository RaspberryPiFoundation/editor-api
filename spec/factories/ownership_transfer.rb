# frozen_string_literal: true

FactoryBot.define do
  factory :ownership_transfer do
    school
    email_address { Faker::Internet.email }
    status { 'pending' }

    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    # Must be persisted even when building an ownership_transfer,
    # since the nominee role check queries the roles table directly
    transient do
      nominee { create(:teacher, school:) }
      requester { create(:owner, school:) }
    end
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy

    nominated_user_id { nominee.id }
    requested_by_user_id { requester.id }
  end
end
