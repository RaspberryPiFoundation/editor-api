# frozen_string_literal: true

module Api
  class FeaturesController < ApiController
    # Public feature discovery endpoint; feature visibility is resolved by Flipper.
    skip_authorization_check only: :index

    def index
      school = current_user&.schools&.first

      enabled_feature_keys = Flipper.features
                                    .select { |feature| Flipper.enabled?(feature.key, school) }
                                    .map(&:key)

      render json: { enabled: enabled_feature_keys }
    end
  end
end
