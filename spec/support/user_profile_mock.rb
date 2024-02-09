# frozen_string_literal: true

module UserProfileMock
  USERS = File.read('spec/fixtures/users.json')

  # Stubs that API that returns user profile data for a given list of UUIDs.
  def stub_userinfo_api
    stub_request(:get, "#{UserinfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserinfoApiClient::API_KEY}" })
      .to_return do |request|
        user_ids = JSON.parse(request.body).fetch('userIds', [])
        indexes = user_ids.map { |user_id| stubbed_user_index(user_id:) }.compact
        users = indexes.map { |user_index| stubbed_user_attributes(user_index:) }

        { body: { users: }.to_json, headers: { 'Content-Type' => 'application/json' } }
      end
  end

  # Stubs the API that returns user profile data for the logged in user.
  def stub_hydra_public_api(user_index: 0, token: 'access-token')
    stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo")
      .with(headers: { Authorization: "Bearer #{token}" })
      .to_return(
        status: 200,
        headers: { content_type: 'application/json' },
        body: stubbed_user_attributes(user_index:).to_json
      )
  end

  # Stubs the API *client* that returns user profile data for the logged in user.
  def stub_fetch_oauth_user(user_index: 0)
    attributes = stubbed_user_attributes(user_index:)
    allow(HydraPublicApiClient).to receive(:fetch_oauth_user).and_return(attributes)
  end

  def stubbed_user_attributes(user_index: 0)
    JSON.parse(USERS)['users'][user_index] if user_index
  end

  def stubbed_user_id(user_index: 0)
    stubbed_user_attributes(user_index:)&.fetch('id')
  end

  def stubbed_user_index(user_id: '00000000-0000-0000-0000-000000000000')
    JSON.parse(USERS)['users'].find_index { |attributes| attributes['id'] == user_id }
  end

  def stubbed_user
    User.from_omniauth(token: 'ignored')
  end
end
