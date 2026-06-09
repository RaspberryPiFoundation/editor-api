# frozen_string_literal: true

module Salesforce
  class Lesson < Salesforce::Base
    self.table_name = 'salesforce.lesson__c'
    self.primary_key = :lesson_uuid__c
  end
end
