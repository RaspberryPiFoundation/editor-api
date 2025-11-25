# frozen_string_literal: true

class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :students, class_name: :ClassStudent, inverse_of: :school_class, dependent: :destroy
  has_many :teachers, class_name: :ClassTeacher, inverse_of: :school_class, dependent: :destroy
  has_many :lessons, dependent: :nullify
  accepts_nested_attributes_for :teachers

  scope :with_teachers, ->(user_id) { joins(:teachers).where(teachers: { id: user_id }) }

  before_validation :assign_class_code, on: %i[create import]

  validates :name, presence: true
  validates :code, uniqueness: { scope: :school_id }, presence: true, format: { with: /\d\d-\d\d-\d\d/, allow_nil: false }
  validate :code_cannot_be_changed
  validate :school_class_has_at_least_one_teacher

  enum :import_origin, { google_classroom: 0 }, validate: { allow_nil: true }

  validates :import_origin, presence: true, on: :import
  validates :import_id, presence: true, on: :import

  validates :import_id, uniqueness: { scope: %i[school_id import_origin] }, if: -> { import_id.present? }

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

  def assign_class_code
    return if code.present?

    5.times do
      self.code = ForEducationCodeGenerator.generate
      return if code_is_unique_within_school?
    end

    errors.add(:code, 'could not be generated')
  end

  def submitted_count
    return 0 if lessons.empty?

    Lesson
      .joins(project: { remixes: { school_project: :school_project_transitions } })
      .where(school_class_id: id)
      .where(
        school_project_transitions: { 
          to_state: 'submitted', 
          most_recent: true 
        }
      )
      .count
  end

  private

  def school_class_has_at_least_one_teacher
    return if teachers.present?

    errors.add(:teachers, 'must have at least one teacher')
  end

  def code_cannot_be_changed
    errors.add(:code, 'cannot be changed after verification') if code_was.present? && code_changed?
  end

  def code_is_unique_within_school?
    code.present? && SchoolClass.where(code:, school:).none?
  end
end
