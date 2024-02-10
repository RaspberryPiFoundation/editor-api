# frozen_string_literal: true

class ClassMember < ApplicationRecord
  belongs_to :school_class
  delegate :school, to: :school_class

  validates :student_id, presence: true, uniqueness: {
    scope: :school_class_id,
    case_sensitive: false
  }
end
