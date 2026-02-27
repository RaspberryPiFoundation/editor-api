# # frozen_string_literal: true

module Salesforce
  class School < Salesforce::Base
    self.table_name = 'salesforce.school__c' # TODO Confirm this - placeholder
    self.primary_key = :school_id__c
    
  end
end
