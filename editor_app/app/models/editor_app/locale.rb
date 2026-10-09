# frozen_string_literal: true

module EditorApp
  module Locale
    DEFAULT = 'en'
    SUPPORTED = %w[en en-US es-LA fr-FR ga-IE].freeze
    SELECTABLE = {
      'en' => 'English (Global)',
      'en-US' => 'English (US)',
      'es-LA' => 'Español (Latinoamericano)',
      'fr-FR' => 'Français'
    }.freeze
    PROJECTS_SITE_OVERRIDES = { 'en-US' => 'en' }.freeze

    def self.resolve(path: nil, cookie: nil, accept_language: nil)
      supported(path) || supported(cookie) || from_accept_language(accept_language) || DEFAULT
    end

    def self.supported(locale)
      locale if SUPPORTED.include?(locale)
    end

    def self.projects_site(locale)
      PROJECTS_SITE_OVERRIDES.fetch(locale.to_s, locale.to_s)
    end

    def self.from_accept_language(header)
      return if header.blank?

      preferences = header.split(',').map { |entry| entry.split(';').first.to_s.strip }
      preferences.find { |preference| SUPPORTED.include?(preference) }
    end
  end
end
