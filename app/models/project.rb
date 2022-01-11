class Project < ApplicationRecord
  before_validation :check_unique_not_null, on: :create
  validates :identifier, presence: true, uniqueness: true
  has_many :components, dependent: :destroy

  require 'phrase_identifier'

  private
    def check_unique_not_null
      self.identifier ||= PhraseIdentifier.generate
      while !Project.find_by(identifier: self.identifier).nil?
        self.identifier = PhraseIdentifier.generate
      end
    end
end