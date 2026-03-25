# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_contact, class: 'Salesforce::Contact') do
    pi_accounts_unique_id__c { SecureRandom.uuid }
  end
end
