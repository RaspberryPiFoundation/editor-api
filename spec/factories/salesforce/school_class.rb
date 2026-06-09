# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_school_class, class: 'Salesforce::SchoolClass') do
    classroomuuid__c { SecureRandom.uuid }
  end
end
