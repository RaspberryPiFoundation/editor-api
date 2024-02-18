# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :school, optional: true
  belongs_to :school_class, optional: true

  validates :user_id, presence: true
  validates :name, presence: true
  validates :visibility, presence: true, inclusion: { in: %w[private school public] }

  before_save :assign_school_from_school_class

  private

  def assign_school_from_school_class
    self.school ||= school_class&.school
  end
end
