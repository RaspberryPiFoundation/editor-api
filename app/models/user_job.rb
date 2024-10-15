# frozen_string_literal: true

class UserJob < ApplicationRecord
  belongs_to :good_job, class_name: 'GoodJob::Job'

  attr_accessor :user
end
