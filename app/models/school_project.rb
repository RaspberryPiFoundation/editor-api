class SchoolProject < ApplicationRecord
  belongs_to :school
  belongs_to :project

  validates :school_id, presence: true
end
