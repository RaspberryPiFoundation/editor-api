# frozen_string_literal: true

FactoryBot.define do
  factory(:salesforce_lesson, class: 'Salesforce::Lesson') do
    lesson_uuid__c { SecureRandom.uuid }
  end
end
