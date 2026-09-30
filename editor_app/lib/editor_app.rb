# frozen_string_literal: true

require 'editor_app/version'
require 'editor_app/engine'

module EditorApp
  def self.hosts
    OriginParser.parse(ENV.fetch('EDITOR_APP_HOSTS', nil))
  end

  def self.serves_host?(host)
    hosts.any? do |pattern|
      pattern.is_a?(Regexp) ? pattern.match?(host) : pattern == host
    end
  end
end
