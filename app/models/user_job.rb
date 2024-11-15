# frozen_string_literal: true

class UserJob < ApplicationRecord
  belongs_to :good_job, class_name: 'GoodJob::Job'

  validates :user_id, presence: true

  attr_accessor :user
end
