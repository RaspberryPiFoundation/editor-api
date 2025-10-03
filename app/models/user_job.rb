# frozen_string_literal: true

class UserJob < ApplicationRecord
  validates :good_job_batch_id, presence: true
  validates :user_id, presence: true

  attr_accessor :user
end
