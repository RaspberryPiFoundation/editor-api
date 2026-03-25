# frozen_string_literal: true

module IdentifiableByCookie
  extend ActiveSupport::Concern
  include ActionController::Cookies

  included do
    before_action :load_current_user
    attr_reader :current_user
  end

  def load_current_user
    token = cookies[:scratch_auth]
    @current_user = User.from_token(token:) if token
  end
end
