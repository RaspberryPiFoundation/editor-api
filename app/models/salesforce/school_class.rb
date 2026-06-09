# frozen_string_literal: true

module Salesforce
  class SchoolClass < Salesforce::Base
    self.table_name = 'salesforce.classroom__c'
    self.primary_key = :classroomuuid__c
  end
end
