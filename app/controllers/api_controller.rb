# frozen_string_literal: true

class ApiController < ActionController::API
  include OauthUser

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, with: -> { notfound }
    rescue_from CanCan::AccessDenied, with: -> { denied }
  end

  private

  def require_oauth_user
    head :unauthorized unless oauth_user_id
  end

  def current_user
    # current_user is required by CanCanCan
    oauth_user_id
  end

  def notfound
    head :not_found
  end

  def denied
    head :forbidden
  end
end
