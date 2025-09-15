# frozen_string_literal: true

class Role < ApplicationRecord
  belongs_to :school

  enum :role, { student: 0, teacher: 1, owner: 2 }

  validates :user_id, presence: true
  validates :role, presence: true, uniqueness: { scope: %i[school_id user_id] }
  validate :students_cannot_have_additional_roles
  validate :users_can_only_have_roles_in_one_school

  has_paper_trail(
    meta: {
      meta_school_id: ->(cm) { cm.school&.id }
    }
  )

  private

  def students_cannot_have_additional_roles
    other_roles = Role.where(user_id:)

    if other_roles.student.any?
      errors.add(:base, "Cannot create #{role} role as this user already has the student role for this school")
    elsif student? && other_roles.any?
      other_role_names = [
        other_roles.map(&:role).join(' and '),
        'role'.pluralize(other_roles.length)
      ].join(' ')
      errors.add(:base, "Cannot create student role as this user already has the #{other_role_names} for this school")
    end
  end

  def users_can_only_have_roles_in_one_school
    schools = Role.where(user_id:).map(&:school)
    return if schools.empty? || (schools.any? && schools.first == school)

    errors.add(:base, 'Cannot create role as this user already has a role in a different school')
  end
end
