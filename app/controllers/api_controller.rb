# frozen_string_literal: true

class ApiController < ActionController::API
  class ::ParameterError < StandardError; end

  include Identifiable

  rescue_from StandardError, with: :internal_server_error
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from CanCan::AccessDenied, with: :denied
  rescue_from CanCan::AuthorizationNotPerformed, with: :authorization_not_performed
  rescue_from ParameterError, with: :unprocessable

  before_action :set_paper_trail_whodunnit
  check_authorization

  private

  def bad_request(exception)
    render_error_as_json(exception, :bad_request)
  end

  def authorize_user
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user
  end

  def denied(_exception)
    if current_user
      render json: { error: 'Forbidden' }, status: :forbidden
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def not_found(exception)
    render_error_as_json(exception, :not_found)
  end

  def unprocessable(exception)
    render_error_as_json(exception, :unprocessable_entity)
  end

  def internal_server_error(exception)
    Sentry.capture_exception(exception)
    render_error_as_json(exception, :internal_server_error)
  end

  def authorization_not_performed(exception)
    raise exception if performed?

    Sentry.capture_exception(exception)
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  def render_error_as_json(exception, status)
    render json: { error: "#{exception.class}: #{exception.message}" }, status:
  end

  def track_event(name, properties = {})
    EventTracker.track!(user_id: current_user.id, name:, properties:)
  end

  def track_project_event(name, project, user_role: nil, student_id: nil)
    EventTracker.track_project_event!(
      name:,
      user_id: current_user.id,
      project:,
      user_role:,
      student_id:
    )
  end
end
