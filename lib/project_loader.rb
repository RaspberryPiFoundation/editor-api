# frozen_string_literal: true

class ProjectLoader
  attr_reader :identifier, :locale

  def initialize(identifier, locales)
    @identifier = identifier
    @locales = [*locales, 'en', nil]
  end

  def load
    projects = Project.where(identifier:, locale: @locales)
    projects.sort_by{ |project| @locales.find_index(project.locale) }.first
  end
end
