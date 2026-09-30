# frozen_string_literal: true

require 'view_component'

module EditorApp
  class Engine < ::Rails::Engine
    isolate_namespace EditorApp

    initializer 'editor_app.assets' do |app|
      app.config.assets.paths << root.join('app/javascript')
    end

    initializer 'editor_app.importmap', before: 'importmap' do |app|
      app.config.importmap.paths << root.join('config/importmap.rb')
      app.config.importmap.cache_sweepers << root.join('app/javascript')
    end

    config.after_initialize do
      I18n.available_locales |= EditorApp::Locale::SUPPORTED.map(&:to_sym)
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
