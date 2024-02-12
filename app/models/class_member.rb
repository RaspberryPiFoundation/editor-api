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
    users = students.map { |user| [user.id, user] }.to_h
    all.map { |member| [member, users[member.student_id]] }
  end

  private

  def student_has_the_school_student_role_for_the_school
    return unless student_id_changed? && errors.blank?

    user = User.from_userinfo(ids: student_id).first
    return unless user && !user.school_student?(organisation_id: school.id)

    msg = "'#{student_id}' does not have the 'school-student' role for organisation '#{school.id}'"
    errors.add(:student, msg)
  end
end
