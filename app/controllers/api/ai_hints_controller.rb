# frozen_string_literal: true

module Api
  class AiHintsController < ApiController
    MAX_REQUEST_SIZE_KB = 100

    before_action :authorize_user
    before_action :check_feature_flag
    before_action :check_request_size, only: :create
    skip_authorization_check

    def show
      ai_hint = AiHint.find_by!(id: params.expect(:id), user_id: current_user.id)

      render json: { status: ai_hint.status, hint: ai_hint.hint }.compact, status: :ok
    end

    def create
      params.require(%i[message trace runtime code])

      ai_hint = AiHint.create!(
        user_id: current_user.id,
        input: params.permit(:message, :trace, :runtime, :code).to_h
      )
      GenerateAiHintJob.perform_later(ai_hint_id: ai_hint.id)

      render json: { id: ai_hint.id }, status: :accepted
    end

    private

    def check_feature_flag
      return if FeatureFlagHelpers.enabled_for_user?(:ai_friendly_errors, current_user, current_user&.schools&.first)

      render json: {}, status: :unauthorized
    end

    def check_request_size
      return if request.body.size <= MAX_REQUEST_SIZE_KB.kilobytes

      render json: { error: "The request was over the max size of #{MAX_REQUEST_SIZE_KB} KB" }, status: :content_too_large
    end
  end
end
