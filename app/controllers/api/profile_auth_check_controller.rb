# frozen_string_literal: true

module Api
  class ProfileAuthCheckController < ApiController
    def index
      return render_not_authorised unless profile_api_eligible_user?

      authorised = ProfileApiClient.check_auth(token: current_user&.token)

      render json: { can_use_profile_api: authorised }, status: :ok
    rescue ProfileApiClient::UnauthorizedError
      render_not_authorised
    end

    private

    def profile_api_eligible_user?
      return false if current_user.blank?
      return false if current_user.student_profile?

      true
    end

    def render_not_authorised
      render json: { can_use_profile_api: false }, status: :ok
    end
  end
end
