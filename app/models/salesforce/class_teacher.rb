# frozen_string_literal: true

module Salesforce
  class ClassTeacher < Salesforce::Base
    self.table_name = 'salesforce.contact_classroom_affiliation__c'
    self.primary_key = :contactclassroomaffiliationuuid__c
  end
end
