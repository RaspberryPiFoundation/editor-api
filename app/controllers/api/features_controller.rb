# frozen_string_literal: true

module Api
  class FeaturesController < ApiController
    def index
      school = current_user&.schools&.first

      enabled_feature_keys = Flipper.features
                                    .select { |feature| Flipper.enabled?(feature.key, school) }
                                    .map(&:key)

      render json: { enabled: enabled_feature_keys }
    end
  end
end
