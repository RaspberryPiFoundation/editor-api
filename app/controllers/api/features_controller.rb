# frozen_string_literal: true

module Api
  class FeaturesController < ApiController
    def index
      Rails.logger.info "Features: #{Flipper.features}"
      features = Flipper.features.map do |feature|
        # todo: reveal only features that are enabled.
        [feature.key, Flipper.enabled?(feature.key, current_user)]
      end

      render json: features.to_h
    end
  end
end
