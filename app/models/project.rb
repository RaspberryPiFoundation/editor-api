# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :school, optional: true
  belongs_to :lesson, optional: true
  belongs_to :parent, optional: true, class_name: :Project, foreign_key: :remixed_from_id, inverse_of: :remixes
  has_many :remixes, dependent: :nullify, class_name: :Project, foreign_key: :remixed_from_id, inverse_of: :parent
  has_many :components, -> { order(default: :desc, name: :asc) }, dependent: :destroy, inverse_of: :project
  has_many :project_errors, dependent: :nullify
  has_many_attached :images

  accepts_nested_attributes_for :components

  before_validation :check_unique_not_null, on: :create

  validates :identifier, presence: true, uniqueness: { scope: :locale }
  validate :identifier_cannot_be_taken_by_another_user
  validates :locale, presence: true, unless: :user_id
  validate :user_has_a_role_within_the_school
  validate :user_is_the_owner_of_the_lesson

  scope :internal_projects, -> { where(user_id: nil) }

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

  # Work around a CanCanCan issue with accepts_nested_attributes_for.
  # https://github.com/CanCanCommunity/cancancan/issues/774
  def components=(array)
    super(array.map { |o| o.is_a?(Hash) ? Component.new(o) : o })
  end

  private

  def check_unique_not_null
    self.identifier ||= PhraseIdentifier.generate
  end

  def identifier_cannot_be_taken_by_another_user
    return if Project.where(identifier: self.identifier).where.not(user_id:).empty?

    errors.add(:identifier, "can't be taken by another user")
  end

  def user_has_a_role_within_the_school
    return unless user_id_changed? && errors.blank? && school

    _, user = with_user

    return if user.blank?
    return if user.school_roles(school).any?

    msg = "'#{user_id}' does not have any roles for organisation '#{school_id}'"
    errors.add(:user, msg)
  end

  def user_is_the_owner_of_the_lesson
    return if !lesson || user_id == lesson.user_id

    errors.add(:user, "'#{user_id}' is not the owner for lesson '#{lesson_id}'")
  end
end
