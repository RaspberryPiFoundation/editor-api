# frozen_string_literal: true

class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :members, class_name: :ClassMember, inverse_of: :school_class, dependent: :destroy

  validates :teacher_id, presence: true
  validates :name, presence: true

  def teacher
    User.from_userinfo(ids: teacher_id).first
  end

  def students
    User.from_userinfo(ids: members.pluck(:student_id))
  end
end
