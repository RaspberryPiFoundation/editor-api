# frozen_string_literal: true

require 'hydra_admin_api'

module AuthenticationConcern
  extend ActiveSupport::Concern

  def current_user_id
    return @current_user_id if @current_user_id

    token = request.headers['Authorization']
    return nil unless token

    @current_user_id = HydraAdminApi.fetch_oauth_user_id(token:)
  end
end
