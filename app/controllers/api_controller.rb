# frozen_string_literal: true

class ApiController < ActionController::API
  class ::ParameterError < StandardError; end

  include Identifiable

  rescue_from ActionController::ParameterMissing, with: -> { bad_request }
  rescue_from ActiveRecord::RecordNotFound, with: -> { not_found }
  rescue_from CanCan::AccessDenied, with: -> { denied }
  rescue_from ParameterError, with: -> { unprocessable }
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: -> { parser_error }

  before_action :set_paper_trail_whodunnit

  private

  def bad_request
    head :bad_request # 400 status
  end

  def authorize_user
    head :unauthorized unless current_user # 401 status
  end

  def denied
    head :forbidden # 403 status
  end

  def not_found
    head :not_found # 404 status
  end

  def unprocessable
    head :unprocessable_entity # 422 status
  end

  def parser_error
    render json: { error: 'Malformed JSON or invalid request body.' }, status: :bad_request
  end
end
