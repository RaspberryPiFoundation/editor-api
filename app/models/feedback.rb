# frozen_string_literal: true

class Feedback < ApplicationRecord
  belongs_to :school_project
  validates :content, presence: true
  validates :user_id, presence: true
  validates :school_project, presence: true
  validate :user_has_the_school_owner_or_school_teacher_role_for_the_school
  validate :user_is_the_class_teacher_for_the_school_project

  def user_has_the_school_owner_or_school_teacher_role_for_the_school
    school = school_project&.school
    return unless user_id_changed? && errors.blank? && school

    user = User.new(id: user_id)
    return if user.school_owner?(school)
    return if user.school_teacher?(school)

    msg = "'#{user_id}' does not have the 'school-owner' or 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:user, msg)
  end

  def user_is_the_class_teacher_for_the_school_project
    school_class = school_project&.project&.parent&.lesson&.school_class
    return if !school_class || school_class.teacher_ids.include?(user_id)

    errors.add(:user, "'#{user_id}' is not the 'school-teacher' for school_project '#{school_project.id}'")
  end
end