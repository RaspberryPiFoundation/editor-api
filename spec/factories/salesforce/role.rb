# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_role, class: 'Salesforce::Role') do
    sequence(:affiliation_id__c)
  end
end
