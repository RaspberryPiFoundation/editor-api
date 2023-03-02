# frozen_string_literal: true

require 'hydra_admin_api'

module HydraAdminApiMock
  def stub_fetch_oauth_user_id(user_id)
    allow(HydraAdminApi).to receive(:fetch_oauth_user_id).and_return(user_id)
  end
end
