# frozen_string_literal: true

class School < ApplicationRecord
  has_many :classes, class_name: :SchoolClass, inverse_of: :school, dependent: :destroy
  has_many :lessons, dependent: :nullify
  has_many :projects, dependent: :nullify

  VALID_URL_REGEX = %r{\A(?:https?:\/\/)?(?:www.)?[a-z0-9]+([-.]{1}[a-z0-9]+)*\.[a-z]{2,6}(\/.*)?\z}ix

  # TODO: To be removed once we move to a separate organisation_id
  validates :id, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :website, presence: true, format: { with: VALID_URL_REGEX, message: I18n.t('validations.school.website') }
  validates :address_line_1, presence: true
  validates :municipality, presence: true
  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.codes }
  validates :reference, uniqueness: { case_sensitive: false, allow_nil: true }, presence: false

  before_validation :normalize_reference

  # TODO: To be removed once we move to a separate organisation_id
  def valid_except_for_id?
    validate
    errors.attribute_names.all? { |name| name == :id }
  end

  def user
    User.from_userinfo(ids: user_id).first
  end

  private

  # Ensure the reference is nil, not an empty string
  def normalize_reference
    self.reference = nil if self.reference.blank?
  end
end
