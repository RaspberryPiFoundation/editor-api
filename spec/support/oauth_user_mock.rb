# frozen_string_literal: true

require 'hydra_admin_api'

module OauthUserMock
  def mock_oauth_user(user_id = nil)
    user_id ||= SecureRandom.uuid

    allow(HydraAdminApi).to receive(:fetch_oauth_user_id).and_return(user_id)
  end
end
