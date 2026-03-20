# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_role, class: 'Salesforce::Role') do
    affiliation_id__c { SecureRandom.uuid }
  end
end
