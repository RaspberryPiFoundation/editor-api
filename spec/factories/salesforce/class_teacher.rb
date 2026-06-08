# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_class_teacher, class: 'Salesforce::ClassTeacher') do
    contactclassroomaffiliationuuid__c { SecureRandom.uuid }
  end
end
