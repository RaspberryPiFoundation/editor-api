# frozen_string_literal: true

class ProjectError < ApplicationRecord
  belongs_to :project, optional: true
  validates :error, presence: true
end
