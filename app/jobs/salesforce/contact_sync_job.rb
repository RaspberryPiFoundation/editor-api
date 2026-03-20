# frozen_string_literal: true

module Salesforce
  class ContactSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::Contact

    def perform(school_id:)
      school = ::School.find(school_id)

      sf_contact = Salesforce::Contact.find_by(pi_accounts_unique_id__c: school.creator_id)
      raise SalesforceRecordNotFound, "Contact not found for creator_id: #{school.creator_id}" unless sf_contact

      sf_contact.experiencecsagreetouxcontact__c = school.creator_agree_to_ux_contact
      sf_contact.save!
    end

    private

    def concurrency_key_id = arguments.first.with_indifferent_access[:school_id]
  end
end
