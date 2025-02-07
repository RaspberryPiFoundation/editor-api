# frozen_string_literal: true

class SchoolProject < ApplicationRecord
  belongs_to :school
  belongs_to :project
end
