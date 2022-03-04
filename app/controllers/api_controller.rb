# frozen_string_literal: true

class ApiController < ActionController::API
  include OauthUser

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, with: -> { return404 }
    rescue_from CanCan::AccessDenied, with: -> { return401 }
  end


  private

  def require_oauth_user
    head :unauthorized unless oauth_user_id
  end

  def current_user
    # current_user is required by CanCanCan
    oauth_user_id
  end

  def return404
    head :not_found
  end

  def return401
    head :unauthorized
  end
end
