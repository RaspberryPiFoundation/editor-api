# frozen_string_literal: true

module Salesforce
  class RoleSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::Role

    FIELD_MAPPINGS = {
      affiliation_id__c: :id,
      contact__r__pi_accounts_unique_id__c: :user_id,
      editor__r__editoruuid__c: :school_id,
      roletype__c: :role,
      offboardedat__c: :archived_at,
      createdat__c: :created_at,
      updatedat__c: :updated_at
    }.freeze

    def perform(role_id:)
      role = ::Role.unscoped.find(role_id)

      return if role.student?

      ensure_parent_synced!(Salesforce::School, :editoruuid__c, role.school_id, 'Editor__c')
      ensure_parent_synced!(Salesforce::Contact, :pi_accounts_unique_id__c, role.user_id, 'Contact')

      sf_role = Salesforce::Role.find_or_initialize_by(affiliation_id__c: role_id)
      sf_role.attributes = sf_role_attributes(role:)

      # We also have a field on the Contact_Editor_Affiliation in Salesforce
      # called Editor_Type__c - this is mapped to the value of role.school.user_origin
      # If, for any reason, we can't get that, we fall back to the School model's default
      # value for user_origin. ::School.new never persists to the DB.
      sf_role.editor_type__c = role.school&.user_origin || ::School.new.user_origin

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
