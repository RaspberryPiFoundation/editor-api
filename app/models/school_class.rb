# frozen_string_literal: true

class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :members, class_name: :ClassMember, inverse_of: :school_class, dependent: :destroy
  has_many :lessons, dependent: :nullify

  validates :teacher_id, presence: true
  validates :name, presence: true
  validate :teacher_has_the_school_teacher_role_for_the_school

  def self.teachers
    User.from_userinfo(ids: pluck(:teacher_id))
  end

  def self.with_teachers
    by_id = teachers.index_by(&:id)
    all.map { |instance| [instance, by_id[instance.teacher_id]] }
  end

  def with_teacher
    [self, User.from_userinfo(ids: teacher_id).first]
  end

  private

  def teacher_has_the_school_teacher_role_for_the_school
    return unless teacher_id_changed? && errors.blank?

    _, user = with_teacher
    return unless user && !user.school_teacher?(school)

    msg = "'#{teacher_id}' does not have the 'school-teacher' role for organisation '#{school.id}'"
    errors.add(:user, msg)
  end
end
