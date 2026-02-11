# frozen_string_literal: true

module Salesforce
  class SchoolSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::School

    FIELD_MAPPINGS = {}.freeze

    STATUS_MAPPINGS = {}.freeze


    def perform(school_id:)
      @school = School.find(id: school_id)
      sf_school = Salesforce::School.find_or_initialize_by(school_id__c: school_id)

      # Make the sf_school match @school.

      sf_school.save!
    end
  end
end
