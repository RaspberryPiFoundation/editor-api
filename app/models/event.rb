# frozen_string_literal: true

class Event < ApplicationRecord
  validates :name, presence: true
  validates :time, presence: true
  validates :user_id, presence: true
end
