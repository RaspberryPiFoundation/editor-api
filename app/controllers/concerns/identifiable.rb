# frozen_string_literal: true

module Identifiable
  extend ActiveSupport::Concern

  included do
    before_action :load_current_user
    attr_reader :current_user
  end

  def load_current_user
    token = request.headers['Authorization']
    @current_user = User.from_token(token:) if token
  end
end
