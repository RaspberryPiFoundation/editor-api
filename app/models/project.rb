# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :school, optional: true
  belongs_to :lesson, optional: true
  belongs_to :parent, optional: true, class_name: :Project, foreign_key: :remixed_from_id, inverse_of: :remixes
  has_many :remixes, dependent: :nullify, class_name: :Project, foreign_key: :remixed_from_id, inverse_of: :parent
  has_many :components, -> { order(default: :desc, name: :asc) }, dependent: :destroy, inverse_of: :project
  has_many :project_errors, dependent: :nullify
  has_many_attached :images
  has_many_attached :videos
  has_many_attached :audio
  has_one :school_project, dependent: :destroy

  accepts_nested_attributes_for :components

  before_validation :check_unique_not_null, on: :create
  before_validation :create_school_project_if_needed

  validates :identifier, presence: true, uniqueness: { scope: :locale }
  validate :identifier_cannot_be_taken_by_another_user
  validates :locale, presence: true, unless: :user_id
  validate :user_has_a_role_within_the_school
  validate :user_is_class_teacher_or_student
  validate :project_with_instructions_must_belong_to_school
  validate :project_with_school_id_has_school_project
  validate :school_project_school_matches_project_school

  default_scope -> { where.not(project_type: 'scratch') }

  scope :internal_projects, -> { where(user_id: nil) }

  has_paper_trail(
    if: ->(p) { p&.school_id },
    meta: {
      meta_remixed_from_id: ->(p) { p&.remixed_from_id },
      meta_school_id: ->(p) { p&.school_id }
    }
  )

  def self.users(current_user)
    school = School.find_by(id: pluck(:school_id))
    SchoolStudent::List.call(school:, token: current_user.token, student_ids: pluck(:user_id).uniq)[:school_students] || []
  end

  def self.with_users(current_user)
    by_id = users(current_user).index_by(&:id)
    all.map { |instance| [instance, by_id[instance.user_id]] }
  end

  def with_user(current_user)
    school = School.find_by(id: school_id)
    students = SchoolStudent::List.call(school:, token: current_user.token,
                                        student_ids: [user_id])[:school_students] || []
    [self, students.first]
  end

  # Work around a CanCanCan issue with accepts_nested_attributes_for.
  # https://github.com/CanCanCommunity/cancancan/issues/774
  def components=(array)
    super(array.map { |o| o.is_a?(Hash) ? Component.new(o) : o })
  end

  def last_edited_at
    # datetime that the project or one of its components was last updated
    [updated_at, components.maximum(:updated_at)].compact.max
  end

  def media
    images + videos + audio
  end

  private

  def check_unique_not_null
    self.identifier ||= PhraseIdentifier.generate
  end

  def create_school_project_if_needed
    return unless school.present? && school_project.nil?

    self.school_project = SchoolProject.new(school:)
  end

  def identifier_cannot_be_taken_by_another_user
    return if Project.where(identifier: self.identifier).where.not(user_id:).empty?

    errors.add(:identifier, "can't be taken by another user")
  end

  def user_has_a_role_within_the_school
    return unless user_id_changed? && errors.blank? && school

    user = User.new(id: user_id)
    return if user.school_roles(school).any?

    msg = "'#{user_id}' does not have any roles for for organisation '#{school_id}'"
    errors.add(:user, msg)
  end

  def user_is_class_teacher_or_student
    # TODO: Revisit the case where the lesson is not associated to a class i.e. when we build a lesson library
    no_lesson = !lesson
    no_school_class = lesson && !lesson.school_class

    return if no_lesson || no_school_class || user_is_class_student || user_is_class_teacher

    errors.add(:user, "'#{user_id}' is not a class member or the owner of the lesson '#{lesson_id}'")
  end

  def user_is_class_student
    lesson&.school_class&.students&.exists?(student_id: user_id)
  end

  def user_is_class_teacher
    lesson&.school_class&.teachers&.exists?(teacher_id: user_id)
  end

  def project_with_instructions_must_belong_to_school
    return unless instructions && !school_id

    errors.add(:instructions, 'Projects with instructions must belong to a school')
  end

  def project_with_school_id_has_school_project
    return unless school_id && !school_project

    errors.add(:school_project, 'Project with school_id must have a school_project')
  end

  def school_project_school_matches_project_school
    return unless school_id && school_project && school_id != school_project.school_id

    errors.add(:school_project, 'School project school_id must match project school_id')
  end
end
