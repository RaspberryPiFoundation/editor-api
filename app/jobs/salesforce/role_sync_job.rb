# frozen_string_literal: true

module Salesforce
  class RoleSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::Role

    FIELD_MAPPINGS = {
      affiliation_id__c: :id,
      contact__r__pi_accounts_unique_id__c: :user_id,
      editor__r__editoruuid__c: :school_id,
      roletype__c: :role,
      createdat__c: :created_at,
      updatedat__c: :updated_at
    }.freeze

    def perform(role_id:)
      role = ::Role.find(role_id)

      return if role.student?

      sf_role = Salesforce::Role.find_or_initialize_by(affiliation_id__c: role_id)
      sf_role.attributes = sf_role_attributes(role:)
      sf_role.save!
    end

    private

    def sf_role_attributes(role:)
      mapped_attributes(role:).to_h do |sf_field, value|
        value = truncate_value(sf_field:, value:) if value.is_a?(String)

        [sf_field, value]
      end
    end

    def mapped_attributes(role:)
      FIELD_MAPPINGS.transform_values do |role_field|
        role.send(role_field)
      end
    end

    def concurrency_key_id = arguments.first.with_indifferent_access[:role_id]
  end
end
