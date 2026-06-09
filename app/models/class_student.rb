# frozen_string_literal: true

class ClassStudent < ApplicationRecord
  belongs_to :school_class
  delegate :school, to: :school_class
  attr_accessor :student

  validates :student_id, presence: true, uniqueness: {
    scope: :school_class_id,
    case_sensitive: false
  }

  validate :student_has_the_school_student_role_for_the_school

  has_paper_trail(
    meta: {
      meta_school_id: ->(cm) { cm.school_class&.school_id }
    }
  )

  after_commit :do_salesforce_sync, on: %i[create destroy], if: -> { FeatureFlags.salesforce_sync? }

  def user_id
    student_id
  end

  private

  # Re-sync the parent SchoolClass when students join or leave so its synced member
  # count stays current, and fan out to every lesson in the class that's visible to
  # students — those carry an assigned-students count that depends on class membership.
  # Query via `school_class_id` rather than the `school_class` association: on cascading
  # destroy the after_commit fires after the parent row has been deleted, so the
  # association would resolve to nil. The FK is still readable on the in-memory record.
  def do_salesforce_sync
    Salesforce::SchoolClassSyncJob.perform_later(school_class_id: school_class_id)
    Lesson.where(school_class_id: school_class_id, visibility: 'students').find_each do |lesson|
      Salesforce::LessonSyncJob.perform_later(lesson_id: lesson.id)
    end
  end

  def student_has_the_school_student_role_for_the_school
    return unless student_id_changed? && errors.blank? && student.present?

    return if student.school_student?(school)

    msg = "'#{student.id}' does not have the 'school-student' role for organisation '#{school.id}'"
    errors.add(:student, msg)
  end
end
