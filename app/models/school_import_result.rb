# frozen_string_literal: true

class SchoolImportResult < ApplicationRecord
  validates :job_id, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :results, presence: true
end
