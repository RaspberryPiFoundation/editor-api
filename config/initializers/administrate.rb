# frozen_string_literal: true

require 'administrate/field/associative'

module Administrate
  module Field
    class Associative < Base
      module Overrides
        def deprecated_option(name)
          name == :class_name ? options.fetch(name) : super
        end
      end
    end
  end
end

# Ref: https://github.com/thoughtbot/administrate/commit/f9c5f1af0bd27dbe8e98d43b2074b96004689ad5
patch_required = Gem::Version.new(Administrate::VERSION) >= Gem::Version.new('1.0.0.beta3')
raise 'Administrate::Field::Associative::Overrides patch is no longer required' if patch_required

Administrate::Field::Associative.prepend(Administrate::Field::Associative::Overrides)
