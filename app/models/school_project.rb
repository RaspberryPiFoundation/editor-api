class SchoolProject < ApplicationRecord
  belongs_to :school
  # belongs_to :lesson
  has_one :project, dependent: :destroy

  validates :school_id, presence: true
  validates :project_id, presence: true
end
