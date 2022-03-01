# frozen_string_literal: true

module OauthUserMock
  def mock_oauth_user(user_id = nil)
    user_id ||= SecureRandom.uuid

    allow_any_instance_of(OauthUser).to receive(:oauth_user_id).and_return(user_id)
  end
end
