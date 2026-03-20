# frozen_string_literal: true

module Salesforce
  class School < Salesforce::Base
    self.table_name = 'salesforce.editor__c'
    self.primary_key = :editoruuid__c
  end
end
