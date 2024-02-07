# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  def identify_user
    token = request.headers['Authorization']
    User.from_omniauth(token:) if token
  end

  def current_user
    @current_user ||= identify_user
  end
end
