# frozen_string_literal: true

class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :students, class_name: :ClassStudent, inverse_of: :school_class, dependent: :destroy
  has_many :teachers, class_name: :ClassTeacher, inverse_of: :school_class, dependent: :destroy
  has_many :lessons, dependent: :nullify
  accepts_nested_attributes_for :teachers

  scope :with_teachers, ->(user_id) { joins(:teachers).where(teachers: { id: user_id }) }

  validates :name, presence: true
  validate :school_class_has_at_least_one_teacher

  has_paper_trail(
    meta: {
      meta_school_id: ->(cm) { cm.school&.id }
    }
  )

  def self.teachers
    teacher_ids = all.map(&:teacher_ids).flatten.uniq
    User.from_userinfo(ids: teacher_ids)
  end

  def self.with_teachers
    by_id = teachers.index_by(&:id)
    all.map { |instance| [instance, instance.teacher_ids.map { |teacher_id| by_id[teacher_id] }] }
  end

  def teacher_ids
    teachers.pluck(:teacher_id)
  end

  def with_teachers
    [self, User.from_userinfo(ids: teacher_ids)]
  end

  private

  def school_class_has_at_least_one_teacher
    return if teachers.present?

    errors.add(:teachers, 'must have at least one teacher')
  end
end
