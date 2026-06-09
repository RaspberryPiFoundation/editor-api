# frozen_string_literal: true

module Salesforce
  class ClassTeacherSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::ClassTeacher

    FIELD_MAPPINGS = {
      contactclassroomaffiliationuuid__c: :id,
      classroom__r__classroomuuid__c: :school_class_id,
      contact_teacher__r__pi_accounts_unique_id__c: :teacher_id,
      createdat__c: :created_at,
      updatedat__c: :updated_at
    }.freeze

    def perform(class_teacher_id:)
      class_teacher = ::ClassTeacher.find(class_teacher_id)

      ensure_parent_synced!(Salesforce::SchoolClass, :classroomuuid__c, class_teacher.school_class_id, 'Classroom__c')
      ensure_parent_synced!(Salesforce::Contact, :pi_accounts_unique_id__c, class_teacher.teacher_id, 'Contact')

      sf_class_teacher = Salesforce::ClassTeacher.find_or_initialize_by(
        contactclassroomaffiliationuuid__c: class_teacher_id
      )
      sf_class_teacher.attributes = sf_class_teacher_attributes(class_teacher:)

      sf_class_teacher.save!
    end

    private

    def sf_class_teacher_attributes(class_teacher:)
      mapped_attributes(class_teacher:).to_h do |sf_field, value|
        value = truncate_value(sf_field:, value:) if value.is_a?(String)

        [sf_field, value]
      end
    end

    def mapped_attributes(class_teacher:)
      FIELD_MAPPINGS.transform_values do |class_teacher_field|
        class_teacher.send(class_teacher_field)
      end
    end

    def concurrency_key_id = arguments.first.with_indifferent_access[:class_teacher_id]
  end
end
