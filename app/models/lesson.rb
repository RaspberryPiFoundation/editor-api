# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :school, optional: true
  belongs_to :school_class, optional: true

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

  private

  def assign_school_from_school_class
    self.school ||= school_class&.school
  end

  # rubocop:disable Metrics/AbcSize
  def user_has_the_school_owner_or_school_teacher_role_for_the_school
    return unless user_id_changed? && errors.blank? && school

    _, user = with_user

    return if user.blank?
    return if user.school_owner?(organisation_id: school.id)
    return if user.school_teacher?(organisation_id: school.id)

    msg = "'#{user_id}' does not have the 'school-owner' or 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:user, msg)
  end
  # rubocop:enable Metrics/AbcSize

  def user_is_the_school_teacher_for_the_school_class
    return if !school_class || user_id == school_class.teacher_id

    errors.add(:user, "'#{user_id}' is not the 'school-teacher' for school_class '#{school_class.id}'")
  end
end
