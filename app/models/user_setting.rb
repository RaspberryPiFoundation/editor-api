# frozen_string_literal: true

# Allowed settings are defined in REGISTRY. Defaults are merged in on read.
class UserSetting < ApplicationRecord
  REGISTRY = {
    'theme' => { values: %w[light dark], default: nil },
    'font_size' => { values: %w[small medium large], default: 'small' },
    'ai_hints_enabled' => { values: [true, false], default: true }
  }.freeze

  validates :user_id, presence: true, uniqueness: true
  validate :settings_must_be_valid

  def self.defaults
    REGISTRY.transform_values { |config| config[:default] }
  end

  def settings_with_defaults
    self.class.defaults.merge(settings)
  end

  # A nil value resets that setting to its default.
  def merge_settings(new_settings)
    merged = settings.slice(*REGISTRY.keys).merge(new_settings.to_h.stringify_keys)
    self.settings = merged.reject { |key, value| value.nil? && REGISTRY.key?(key) }
  end

  private

  def settings_must_be_valid
    unless settings.is_a?(Hash)
      errors.add(:settings, 'must be an object')
      return
    end

    settings.each do |key, value|
      config = REGISTRY[key]

      if config.nil?
        errors.add(:settings, "'#{key}' is not a valid setting")
      elsif config[:values].exclude?(value)
        errors.add(:settings, "'#{value}' is not a valid value for '#{key}'")
      end
    end
  end
end
