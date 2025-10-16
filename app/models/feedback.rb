# frozen_string_literal: true

class Feedback < ApplicationRecord
  belongs_to :school_project
  validates :content, presence: true
  validates :user_id, presence: true
  validate :user_has_the_school_owner_or_school_teacher_role_for_the_school
  validate :parent_project_belongs_to_lesson
  validate :parent_project_belongs_to_school_class
  validate :user_is_the_class_teacher_for_the_school_project

  has_paper_trail(
    meta: {
      meta_school_project_id: ->(f) { f.school_project&.id },
      meta_school_id: ->(c) { c.school_project&.school_id }
    }
  )

  def user_has_the_school_owner_or_school_teacher_role_for_the_school
    school = school_project&.school
    return unless user_id_changed? && errors.blank? && school

    user = User.new(id: user_id)
    return if user.school_owner?(school)
    return if user.school_teacher?(school)

    msg = "'#{user_id}' does not have the 'school-owner' or 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:user, msg)
  end

  def parent_project_belongs_to_lesson
    parent_project = school_project&.project&.parent
    return if parent_project&.lesson_id.present?

    msg = "Parent project '#{parent_project&.id}' does not belong to a 'lesson'"
    errors.add(:user, msg)
  end

  def parent_project_belongs_to_school_class
    parent_project = school_project&.project&.parent
    return if parent_project&.lesson&.school_class_id.present?

    msg = "Parent project '#{parent_project&.id}' does not belong to a 'school-class'"
    errors.add(:user, msg)
  end

  def user_is_the_class_teacher_for_the_school_project
    return if !school_project || school_class&.teacher_ids&.include?(user_id)

    errors.add(:user, "'#{user_id}' is not the 'school-teacher' for school_project '#{school_project.id}'")
  end

  private

  def school_class
    school_project&.project&.parent&.lesson&.school_class
  end
end
