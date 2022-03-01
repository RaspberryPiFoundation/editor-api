# frozen_string_literal: true

class ApiController < ActionController::API
  include OauthUser

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, with: -> { return404 }
  end

  private

  def require_oauth_user
    head :unauthorized unless oauth_user_id
  end

  def return404
    render json: { error: '404 Not found' }, status: :not_found
  end
end
