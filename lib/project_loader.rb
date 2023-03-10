# frozen_string_literal: true

class ProjectLoader
  attr_reader :identifier, :locale

  def initialize(identifier, locale)
    @identifier = identifier
    @locale = locale
  end

  def load
    project = Project.find_by(identifier:, locale:)
    project ||= Project.find_by(identifier:, locale: 'en') unless locale == 'en'
    project || Project.find_by(identifier:, locale: nil)
  end
end
