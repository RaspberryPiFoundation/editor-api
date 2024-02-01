# frozen_string_literal: true

class SchoolClass < ApplicationRecord
  belongs_to :school
  validates :teacher_id, presence: true
  validates :name, presence: true
end
