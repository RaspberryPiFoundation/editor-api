# frozen_string_literal: true

class ClassTeacher < ApplicationRecord
  belongs_to :school_class
  delegate :school, to: :school_class
  attr_accessor :teacher

  validates :teacher_id, presence: true, uniqueness: {
    scope: :school_class_id,
    case_sensitive: false
  }

  validate :teacher_has_the_school_teacher_role_for_the_school

  has_paper_trail(
    meta: {
      meta_school_id: ->(cm) { cm.school_class&.school_id }
    }
  )

  # Re-sync the parent SchoolClass on add/remove so its synced teacher/member counts
  # stay current. Only :create syncs the ClassTeacher itself — a destroyed record has
  # nothing to publish.
  after_commit :enqueue_school_class_sync, on: %i[create destroy], if: -> { FeatureFlags.salesforce_sync? }
  after_commit :enqueue_class_teacher_sync, on: :create, if: -> { FeatureFlags.salesforce_sync? }

  def user_id
    teacher_id
  end

  private

  def enqueue_school_class_sync
    Salesforce::SchoolClassSyncJob.perform_later(school_class_id: school_class_id)
  end

  def enqueue_class_teacher_sync
    Salesforce::ClassTeacherSyncJob.perform_later(class_teacher_id: id)
  end

  def teacher_has_the_school_teacher_role_for_the_school
    return unless teacher_id_changed? && errors.blank? && teacher.present?

    return if teacher.school_teacher?(school)

    msg = "'#{teacher.id}' does not have the 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:teacher, msg)
  end
end
