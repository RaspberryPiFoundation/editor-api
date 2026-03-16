# frozen_string_literal: true

class ScratchAsset < ApplicationRecord
  validates :filename, presence: true

  has_one_attached :file
end
