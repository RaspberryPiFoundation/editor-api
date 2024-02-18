# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :school_class, optional: true

  validates :user_id, presence: true
  validates :name, presence: true
  validates :visibility, presence: true, inclusion: { in: %w[private school public] }
end
