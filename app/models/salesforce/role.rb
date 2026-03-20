# frozen_string_literal: true

module Salesforce
  class Role < Salesforce::Base
    self.table_name = 'salesforce.contact_editor_affiliation__c'
    self.primary_key = :affiliation_id__c
  end
end
