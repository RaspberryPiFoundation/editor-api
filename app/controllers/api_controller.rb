# frozen_string_literal: true

class ApiController < ActionController::API
  class ::ParameterError < StandardError; end

  include Identifiable

  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from CanCan::AccessDenied, with: :denied
  rescue_from ParameterError, with: :unprocessable

  before_action :set_paper_trail_whodunnit

  private

  def bad_request(exception)
    render json: { error: "#{exception.class}: #{exception.message}" }, status: :bad_request
  end

  def authorize_user
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def denied(exception)
    render json: { error: "#{exception.class}: #{exception.message}" }, status: :forbidden
  end

  def not_found(exception)
    render json: { error: "#{exception.class}: #{exception.message}" }, status: :not_found
  end

  def unprocessable(exception)
    render json: { error: "#{exception.class}: #{exception.message}" }, status: :unprocessable_entity
  end
end
