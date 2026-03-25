# frozen_string_literal: true

module Salesforce
  class Contact < Salesforce::Base
    self.table_name = 'salesforce.contact'
    self.primary_key = :pi_accounts_unique_id__c
  end
end
