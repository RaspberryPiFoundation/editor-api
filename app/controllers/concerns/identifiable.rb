# frozen_string_literal: true

require 'hydra_admin_api'

module Identifiable
  extend ActiveSupport::Concern

  def identify_user
    token = request.headers['Authorization']
    return nil unless token

    HydraAdminApi.fetch_oauth_user_id(token:)
  end

  def current_user_id
    @current_user_id ||= identify_user
  end

  # current_user is required by CanCanCan
  alias current_user current_user_id
end
