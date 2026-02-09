# frozen_string_literal: true

class Lesson < ApplicationRecord
  self.ignored_columns += [:archived_at]

  belongs_to :school, optional: true
  belongs_to :school_class, optional: true
  belongs_to :parent, optional: true, class_name: :Lesson, foreign_key: :copied_from_id, inverse_of: :copies
  has_many :copies, dependent: :nullify, class_name: :Lesson, foreign_key: :copied_from_id, inverse_of: :parent
  has_one :project, dependent: :destroy
  accepts_nested_attributes_for :project

  before_validation :assign_school_from_school_class

  validates :user_id, presence: true
  validates :name, presence: true
  validates :visibility, presence: true, inclusion: { in: %w[private teachers students public] }

  validate :user_has_the_school_owner_or_school_teacher_role_for_the_school
  validate :user_is_the_school_teacher_for_the_school_class

  def self.users
    User.from_userinfo(ids: pluck(:user_id))
  end

  def self.with_users
    by_id = users.index_by(&:id)
    all.map { |instance| [instance, by_id[instance.user_id]] }
  end

  def with_user
    [self, User.from_userinfo(ids: user_id).first]
  end

  def submitted_count
    return 0 unless project

    project.remixes.count { |remix| remix.school_project&.submitted? }
  end

  private

  def assign_school_from_school_class
    self.school ||= school_class&.school
  end

  def user_has_the_school_owner_or_school_teacher_role_for_the_school
    return unless user_id_changed? && errors.blank? && school

    user = User.new(id: user_id)
    return if user.school_owner?(school)
    return if user.school_teacher?(school)

    msg = "'#{user_id}' does not have the 'school-owner' or 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:user, msg)
  end

  def user_is_the_school_teacher_for_the_school_class
    return if !school_class || school_class.teacher_ids.include?(user_id)

    errors.add(:user, "'#{user_id}' is not the 'school-teacher' for school_class '#{school_class.id}'")
  end
end
