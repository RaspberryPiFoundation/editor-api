# frozen_string_literal: true

module Salesforce
  class SchoolClassSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::SchoolClass

    FIELD_MAPPINGS = {
      classroomuuid__c: :id,
      editor__r__editoruuid__c: :school_id,
      classroomtitle__c: :name,
      createdat__c: :created_at,
      updatedat__c: :updated_at
    }.freeze

    def perform(school_class_id:)
      school_class = ::SchoolClass.find(school_class_id)

      ensure_parent_synced!(Salesforce::School, :editoruuid__c, school_class.school_id, 'Editor__c')

      sf_school_class = Salesforce::SchoolClass.find_or_initialize_by(classroomuuid__c: school_class_id)
      sf_school_class.attributes = sf_school_class_attributes(school_class:)

      sf_school_class.save!
    end

    private

    def sf_school_class_attributes(school_class:)
      mapped_attributes(school_class:).merge(
        numberofmembers__c: school_class.students.count,
        lastsyncdate__c: Time.current
      ).to_h do |sf_field, value|
        value = truncate_value(sf_field:, value:) if value.is_a?(String)

        [sf_field, value]
      end
    end

    def mapped_attributes(school_class:)
      FIELD_MAPPINGS.transform_values do |school_class_field|
        school_class.send(school_class_field)
      end
    end

    def concurrency_key_id = arguments.first.with_indifferent_access[:school_class_id]
  end
end
