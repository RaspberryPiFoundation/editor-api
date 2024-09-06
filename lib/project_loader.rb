# frozen_string_literal: true

class ProjectLoader
  attr_reader :identifier, :locale

  def initialize(identifier, locales)
    @identifier = identifier
    @locales = [*locales, 'en', nil]
  end

  def load
    projects = Project.where(identifier:, locale: @locales).includes(images_attachments: :blob)
    projects.min_by { |project| @locales.find_index(project.locale) }
  end
end
