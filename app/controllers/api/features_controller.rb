# frozen_string_literal: true

module Api
  class FeaturesController < ApiController
    def index
      features = Flipper.features.map do |feature|
        [feature.key, Flipper.enabled?(feature.key, current_user&.schools&.first)]
      end

      render json: features.to_h
    end
  end
end
