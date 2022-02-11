# frozen_string_literal: true

require 'phrase_identifier'

class Project < ApplicationRecord
  before_validation :check_unique_not_null, on: :create
  validates :identifier, presence: true, uniqueness: true
  has_many :components, dependent: :destroy

  private

  def check_unique_not_null
    self.identifier ||= PhraseIdentifier.generate
    self.identifier = PhraseIdentifier.generate until Project.find_by(identifier: self.identifier).nil?
  end
end
