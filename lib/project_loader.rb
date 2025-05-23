# frozen_string_literal: true

class ProjectLoader
  attr_reader :identifier, :locale

  def initialize(identifier, locales)
    @identifier = identifier
    @locales = [*locales, 'en', nil]
  end

  def load(include_images: false)
    query = Current.project_scope
    query = query.where(identifier:, locale: @locales)
    query = query.includes(images_attachments: :blob) if include_images
    query.min_by { |project| @locales.find_index(project.locale) }
  end
end
