# frozen_string_literal: true

class ClassMember < ApplicationRecord
  belongs_to :school_class
  delegate :school, to: :school_class

  validates :student_id, presence: true, uniqueness: {
    scope: :school_class_id,
    case_sensitive: false
  }

  validate :student_has_the_school_student_role_for_the_school

  def self.students
    User.from_userinfo(ids: pluck(:student_id))
  end

  def self.with_students
    by_id = students.index_by(&:id)
    all.map { |instance| [instance, by_id[instance.student_id]] }
  end

  def with_student
    [self, User.from_userinfo(ids: student_id).first]
  end

  private

  def student_has_the_school_student_role_for_the_school
    return unless student_id_changed? && errors.blank?

    _, user = with_student
    return unless user && !user.school_student?(organisation_id: school.id)

    msg = "'#{student_id}' does not have the 'school-student' role for organisation '#{school.id}'"
    errors.add(:student, msg)
  end
end
