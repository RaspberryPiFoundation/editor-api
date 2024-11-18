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

  private

  def teacher_has_the_school_teacher_role_for_the_school
    return unless teacher_id_changed? && errors.blank? && teacher.present?

    return if teacher.school_teacher?(school)

    msg = "'#{teacher.id}' does not have the 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:teacher, msg)
  end
end
