# frozen_string_literal: true

class School < ApplicationRecord
  has_many :classes, class_name: :SchoolClass, inverse_of: :school, dependent: :destroy
  has_many :lessons, dependent: :nullify
  has_many :projects, dependent: :nullify

  validates :name, presence: true
  validates :website, presence: true
  validates :address_line_1, presence: true
  validates :municipality, presence: true
  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.codes }
  validates :reference, uniqueness: { case_sensitive: false, allow_nil: true }
end
