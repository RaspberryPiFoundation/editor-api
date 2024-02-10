# frozen_string_literal: true

class School < ApplicationRecord
  has_many :classes, class_name: :SchoolClass, inverse_of: :school, dependent: :destroy

  validates :organisation_id, presence: true, uniqueness: { case_sensitive: false }
  validates :owner_id, presence: true
  validates :name, presence: true
  validates :reference, uniqueness: { case_sensitive: false, allow_nil: true }
  validates :address_line_1, presence: true # rubocop:disable Naming/VariableNumber
  validates :municipality, presence: true
  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.codes }
  validate :owner_has_the_school_owner_role_for_the_school

  def owner
    User.from_userinfo(ids: owner_id).first
  end

  def valid_except_for_organisation?
    validate
    errors.attribute_names.all? { |name| name == :organisation_id }
  end

  private

  def owner_has_the_school_owner_role_for_the_school
    return unless owner_id_changed? && organisation_id && errors.blank?

    user = owner
    return unless user && !user.school_owner?(organisation_id:)

    errors.add(:owner, "'#{owner_id}' does not have the 'school-owner' role for organisation '#{organisation_id}'")
  end
end
