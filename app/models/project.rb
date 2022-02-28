# frozen_string_literal: true

require 'phrase_identifier'

class Project < ApplicationRecord
  before_validation :check_unique_not_null, on: :create
  validates :identifier, presence: true, uniqueness: true
  # belongs_to :parent_project, type: :uuid, class_name: "Project"
  has_many :components, -> { order(:index) }, dependent: :destroy, inverse_of: :project

  private

  def check_unique_not_null
    self.identifier ||= PhraseIdentifier.generate
    self.identifier = PhraseIdentifier.generate until Project.find_by(identifier: self.identifier).nil?
  end
end
