# frozen_string_literal: true

require 'hydra_admin_api'

class ApiController < ActionController::API
  unless Rails.application.config.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, with: -> { notfound }
    rescue_from CanCan::AccessDenied, with: -> { denied }
  end

  private

  def authorize_user
    head :unauthorized unless current_user
  end

  def current_user
    return @current_user if @current_user

    token = request.headers['Authorization']
    return nil unless token

    @current_user = HydraAdminApi.fetch_oauth_user_id(token:)
  end

  def notfound
    head :not_found
  end

  def denied
    head :forbidden
  end
end
