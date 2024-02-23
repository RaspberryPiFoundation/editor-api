# frozen_string_literal: true

class School < ApplicationRecord
  has_many :classes, class_name: :SchoolClass, inverse_of: :school, dependent: :destroy
  has_many :lessons, dependent: :nullify
  has_many :projects, dependent: :nullify

  validates :id, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :reference, uniqueness: { case_sensitive: false, allow_nil: true }
  validates :address_line_1, presence: true # rubocop:disable Naming/VariableNumber
  validates :municipality, presence: true
  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.codes }

  def valid_except_for_id?
    validate
    errors.attribute_names.all? { |name| name == :id }
  end
end
