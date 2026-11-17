# frozen_string_literal: true

# Per-user editor preferences (theme, font size, etc).
#
# Settings live in a single jsonb column. The list of allowed settings is
# defined in REGISTRY, so adding/removing a setting is a code change only
# (no migration). Only values the user has changed are stored; defaults are
# merged in on read.
class UserSetting < ApplicationRecord
  REGISTRY = {
    'theme' => { values: %w[light dark], default: nil },
    'font_size' => { values: %w[small medium large], default: 'small' },
    'ai_friendly_errors' => { values: [true, false], default: true }
  }.freeze

  validates :user_id, presence: true, uniqueness: true
  validate :settings_must_be_valid

  def self.defaults
    REGISTRY.transform_values { |config| config[:default] }
  end

  # Settings for a user, falling back to defaults if they have no row yet.
  def self.for_user(user_id)
    find_by(user_id:)&.merged_settings || defaults
  end

  # Stored values merged over defaults. Keys removed from REGISTRY are ignored.
  def merged_settings
    self.class.defaults.merge(settings.slice(*REGISTRY.keys))
  end

  # Partial update. A nil value resets that setting to its default.
  # Keys no longer in REGISTRY are dropped from stored data. Unknown keys are
  # kept (even if nil) so validation rejects them.
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
