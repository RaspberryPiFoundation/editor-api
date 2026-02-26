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

  def user_id
    student_id
  end

  private

  def student_has_the_school_student_role_for_the_school
    return unless student_id_changed? && errors.blank? && student.present?

    return if student.school_student?(school)

    msg = "'#{student.id}' does not have the 'school-student' role for organisation '#{school.id}'"
    errors.add(:student, msg)
  end
end
