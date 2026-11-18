# frozen_string_literal: true

class ProjectLoader
  SUPPORTED_LOCALE_FORMAT = /\A[a-zA-Z-]{2,8}\z/

  attr_reader :identifier, :locale

  def initialize(identifier, locales)
    @identifier = identifier
    @locales = supported_locales(locales) + ['en', nil]
  end

  def load(include_images: false)
    query = Project.where(identifier:, locale: @locales)
    query = query.includes(images_attachments: :blob) if include_images
    query.min_by { |project| @locales.find_index(project.locale) }
  end

  private

  def supported_locales(locales)
    [*locales].select { |locale| SUPPORTED_LOCALE_FORMAT.match?(locale.to_s) }
  end
end
