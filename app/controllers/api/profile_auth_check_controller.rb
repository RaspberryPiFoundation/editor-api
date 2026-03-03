# frozen_string_literal: true

module Api
  class ProfileAuthCheckController < ApiController
    def index
      authorised = ProfileApiClient.check_auth(token: current_user&.token)

      render json: { can_use_profile_api: authorised }, status: :ok
    rescue ProfileApiClient::UnauthorizedError
      render json: { can_use_profile_api: false }, status: :ok
    end
  end
end
