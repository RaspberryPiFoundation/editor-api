# frozen_string_literal: true

class ProjectLoader
  attr_reader :identifier, :locale, :is_live

  def initialize(identifier, locales)
    @identifier = identifier
    @locales = [*locales, 'en', nil]
    # @is_live = true
  end

  def load
    projects = Project.where(identifier:, locale: @locales)
    projects.min_by { |project| @locales.find_index(project.locale) }
  end
end
