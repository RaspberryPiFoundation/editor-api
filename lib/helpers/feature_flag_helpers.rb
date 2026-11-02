# frozen_string_literal: true

class FeatureFlagHelpers
  def self.enabled_for_user?(feature_key, user, school)
    Flipper.enabled?(feature_key, user, school)
  end
end
