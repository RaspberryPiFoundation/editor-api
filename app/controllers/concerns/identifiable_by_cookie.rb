# frozen_string_literal: true

module IdentifiableByCookie
  extend ActiveSupport::Concern
  include ActionController::Cookies

  def identify_user
    token = cookies[:scratch_auth]
    User.from_token(token:) if token
  end

  def current_user
    @current_user ||= identify_user
  end
end
