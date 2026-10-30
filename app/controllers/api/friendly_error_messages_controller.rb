# frozen_string_literal: true

module Api
  class FriendlyErrorMessagesController < ApiController
    MAX_REQUEST_SIZE_KB = 100

    before_action :authorize_user
    skip_authorization_check only: :show

    def show
      return render json: {}, status: :unauthorized unless Flipper.enabled?(:ai_friendly_errors)
      return render json: { error: "The request was over the max size of #{MAX_REQUEST_SIZE_KB} KB" }, status: :content_too_large if request.body.size > MAX_REQUEST_SIZE_KB.kilobytes

      params.require(%i[message trace runtime code])

      render json: { result: 'ok' }
    end
  end
end
