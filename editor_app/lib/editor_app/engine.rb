# frozen_string_literal: true

require 'view_component'

module EditorApp
  class Engine < ::Rails::Engine
    isolate_namespace EditorApp

    config.after_initialize do
      I18n.available_locales |= EditorApp::Locale::SUPPORTED.map(&:to_sym)
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
