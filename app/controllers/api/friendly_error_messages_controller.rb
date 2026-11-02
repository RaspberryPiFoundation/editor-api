# frozen_string_literal: true

module Api
  class FriendlyErrorMessagesController < ApiController
    MAX_REQUEST_SIZE_KB = 100

    before_action :authorize_user
    skip_authorization_check only: :show

    rescue_from FriendlyErrorMessagesInferenceClient::Error, with: :bad_gateway

    def show
      return render json: {}, status: :unauthorized unless FeatureFlagHelpers.enabled_for_user? :ai_friendly_errors, current_user, current_user&.schools&.first
      return render json: { error: "The request was over the max size of #{MAX_REQUEST_SIZE_KB} KB" }, status: :content_too_large if request.body.size > MAX_REQUEST_SIZE_KB.kilobytes

      params.require(%i[message trace runtime code])

      fem = FriendlyErrorMessagesInferenceClient.new.get_message(
        params[:message],
        params[:trace],
        params[:runtime],
        params[:code]
      )

      render json: { fem: }, status: :ok
    end
  end
end
