# frozen_string_literal: true

class ClassMember < ApplicationRecord
  belongs_to :school_class
  delegate :school, to: :school_class

  validates :student_id, presence: true, uniqueness: {
    scope: :school_class_id,
    case_sensitive: false
  }

  validate :student_has_the_school_student_role_for_the_school

  private

  def student_has_the_school_student_role_for_the_school
    return unless student_id_changed? && errors.blank?

    user = student
    return unless user && !user.school_student?(organisation_id: school.id)

    msg = "'#{student_id}' does not have the 'school-student' role for organisation '#{school.id}'"
    errors.add(:student, msg)
  end

  # Intentionally make this private to avoid N API calls.
  # Prefer using SchoolClass#students which makes 1 API call.
  def student
    User.from_userinfo(ids: student_id).first
  end
end
