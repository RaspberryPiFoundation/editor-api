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
end
