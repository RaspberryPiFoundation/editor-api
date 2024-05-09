# frozen_string_literal: true

class Role < ApplicationRecord
  belongs_to :school

  enum :role, %i[student teacher owner]

  validates :user_id, presence: true
  validates :role, presence: true, uniqueness: { scope: %i[school_id user_id] }
end
