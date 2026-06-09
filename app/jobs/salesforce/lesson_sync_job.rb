# frozen_string_literal: true

module Salesforce
  class LessonSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::Lesson

    FIELD_MAPPINGS = {
      lesson_uuid__c: :id,
      classroom__r__classroomuuid__c: :school_class_id,
      lessontitle__c: :name,
      createdat__c: :created_at,
      updatedat__c: :updated_at
    }.freeze

    def perform(lesson_id:)
      lesson = ::Lesson.find(lesson_id)
      return if lesson.school_class_id.blank?

      ensure_parent_synced!(Salesforce::SchoolClass, :classroomuuid__c, lesson.school_class_id, 'Classroom__c')

      sf_lesson = Salesforce::Lesson.find_or_initialize_by(lesson_uuid__c: lesson_id)
      sf_lesson.attributes = sf_lesson_attributes(lesson:)

      sf_lesson.save!
    end

    private

    def sf_lesson_attributes(lesson:)
      mapped_attributes(lesson:).merge(
        teacherprojecttitle__c: lesson.project&.name,
        teacherprojecttype__c: lesson.project&.project_type,
        numberofassignedprojects__c: assigned_projects_count(lesson),
        # Sum of the two completion paths: state-machine `:submitted` (Code Editor flow)
        # and `school_projects.finished` (Experience CS flow). They are mutually exclusive
        # per project, so the sum is safe.
        numberofcompletedprojects__c: lesson.submitted_projects_count + lesson.finished_projects_count,
        lastsyncdate__c: Time.current
      ).to_h do |sf_field, value|
        value = truncate_value(sf_field:, value:) if value.is_a?(String)

        [sf_field, value]
      end
    end

    def mapped_attributes(lesson:)
      FIELD_MAPPINGS.transform_values do |lesson_field|
        lesson.send(lesson_field)
      end
    end

    # A lesson is "assigned" to every student in its class iff it's visible to them
    # (visibility == 'students'). Other visibilities aren't assigned to students at all.
    def assigned_projects_count(lesson)
      return 0 unless lesson.visibility == 'students'

      lesson.school_class.students.count
    end

    def concurrency_key_id = arguments.first.with_indifferent_access[:lesson_id]
  end
end
