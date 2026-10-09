# frozen_string_literal: true

require_relative 'lib/editor_app/version'

Gem::Specification.new do |spec|
  spec.name        = 'editor_app'
  spec.version     = EditorApp::VERSION
  spec.authors     = ['Raspberry Pi Foundation']
  spec.summary     = 'Code Editor web app'
  spec.description = 'Server-rendered pages for the Raspberry Pi Code Editor'
  spec.homepage    = 'https://github.com/RaspberryPiFoundation/editor-api'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 4.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/raspberrypifoundation'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{app,config,lib}/**/*', 'README.md']

  spec.add_dependency 'rails', '>= 8.1'
  spec.add_dependency 'view_component'
end
