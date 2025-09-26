# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :school, optional: true
  belongs_to :school_class, optional: true
  belongs_to :parent, optional: true, class_name: :Lesson, foreign_key: :copied_from_id, inverse_of: :copies
  has_many :copies, dependent: :nullify, class_name: :Lesson, foreign_key: :copied_from_id, inverse_of: :parent
  has_one :project, dependent: :nullify
  accepts_nested_attributes_for :project

  before_validation :assign_school_from_school_class
  before_destroy -> { throw :abort }

  validates :user_id, presence: true
  validates :name, presence: true
  validates :visibility, presence: true, inclusion: { in: %w[private teachers students public] }

  validate :user_has_the_school_owner_or_school_teacher_role_for_the_school
  validate :user_is_the_school_teacher_for_the_school_class
  validate :remixed_lesson_projects_come_from_public_projects

  scope :archived, -> { where.not(archived_at: nil) }
  scope :unarchived, -> { where(archived_at: nil) }

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

  def archived?
    archived_at.present?
  end

  def archive!
    return if archived?

    self.archived_at = Time.now.utc
    save!(validate: false)
  end

  def unarchive!
    return unless archived?

    self.archived_at = nil
    save!(validate: false)
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

  def remixed_lesson_projects_come_from_public_projects
    return if !project || !project.remixed_from_id

    original_project = Project.find_by(id: project.remixed_from_id)
    return if original_project&.user_id.nil?

    errors.add(:project, "remixed project '#{original_project.id}' is not public")
  end
end
