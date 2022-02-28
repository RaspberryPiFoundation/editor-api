# frozen_string_literal: true

require 'phrase_identifier'

class Project < ApplicationRecord
  before_validation :check_unique_not_null, on: :create
  validates :identifier, presence: true, uniqueness: true
  belongs_to :parent, class_name: "Project", foreign_key: "remixed_from_id", optional: true
  has_many :components, -> { order(:index) }, dependent: :destroy, inverse_of: :project
  has_many :children, class_name: "Project", foreign_key: "remixed_from_id"

  private

  def check_unique_not_null
    self.identifier ||= PhraseIdentifier.generate
    self.identifier = PhraseIdentifier.generate until Project.find_by(identifier: self.identifier).nil?
  end
end
