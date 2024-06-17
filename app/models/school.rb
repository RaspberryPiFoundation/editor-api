# frozen_string_literal: true

class School < ApplicationRecord
  has_many :classes, class_name: :SchoolClass, inverse_of: :school, dependent: :destroy
  has_many :lessons, dependent: :nullify
  has_many :projects, dependent: :nullify
  has_many :roles, dependent: :nullify

  VALID_URL_REGEX = %r{\A(?:https?://)?(?:www.)?[a-z0-9]+([-.]{1}[a-z0-9]+)*\.[a-z]{2,6}(/.*)?\z}ix

  validates :name, presence: true
  validates :website, presence: true, format: { with: VALID_URL_REGEX, message: I18n.t('validations.school.website') }
  validates :address_line_1, presence: true
  validates :municipality, presence: true
  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.codes }
  validates :reference, uniqueness: { case_sensitive: false, allow_nil: true }, presence: false
  validates :creator_id, presence: true, uniqueness: true
  validates :creator_agree_authority, presence: true, acceptance: true
  validates :creator_agree_terms_and_conditions, presence: true, acceptance: true
  validates :rejected_at, absence: { if: proc { |school| school.verified? } }
  validates :verified_at, absence: { if: proc { |school| school.rejected? } }
  validate :verified_at_cannot_be_changed
  validate :rejected_at_cannot_be_changed

  before_validation :normalize_reference

  def self.find_for_user!(user)
    school = Role.find_by(user_id: user.id)&.school || find_by(creator_id: user.id)
    raise ActiveRecord::RecordNotFound unless school

    school
  end

  def creator
    User.from_userinfo(ids: creator_id).first
  end

  def verified?
    verified_at.present?
  end

  def rejected?
    rejected_at.present?
  end

  private

  # Ensure the reference is nil, not an empty string
  def normalize_reference
    self.reference = nil if reference.blank?
  end

  def verified_at_cannot_be_changed
    errors.add(:verified_at, 'cannot be changed after verification') if verified_at_was.present? && verified_at_changed?
  end

  def rejected_at_cannot_be_changed
    errors.add(:rejected_at, 'cannot be changed after rejection') if rejected_at_was.present? && rejected_at_changed?
  end
end
