# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_school, class: 'Salesforce::School') do
    editoruuid__c { SecureRandom.uuid }
  end
end
