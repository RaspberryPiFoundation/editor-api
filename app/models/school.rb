# frozen_string_literal: true

class School < ApplicationRecord
  validates :organisation_id, presence: true, uniqueness: { case_sensitive: false }
  validates :owner_id, presence: true
  validates :name, presence: true
end
