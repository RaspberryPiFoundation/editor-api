# frozen_string_literal: true

module UserProfileMock
  TOKEN = 'fake-user-access-token'

  def stub_user_info_api_for_unknown_users(user_id:)
    stub_user_info_api(user_id:, users: [])
  end

  def stub_user_info_api_for(user)
    stub_user_info_api(user_id: user.id, users: [user_to_hash(user)])
  end

  def authenticated_in_hydra_as(user)
    stub_hydra_public_api(user_to_hash(user))
  end

  def unauthenticated_in_hydra
    stub_hydra_public_api({})
  end

  def stubbed_user
    User.from_token(token: TOKEN)
  end

  private

  def user_to_hash(user)
    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end

  # Stubs the API that returns user profile data for the logged in user.
  def stub_hydra_public_api(user)
    stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo")
      .with(headers: { Authorization: "Bearer #{TOKEN}" })
      .to_return(
        status: 200,
        headers: { content_type: 'application/json' },
        body: user.to_json
      )
  end

  def stub_user_info_api(user_id:, users:)
    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" }, body: /#{user_id}/)
      .to_return({ body: { users: }.to_json, headers: { 'Content-Type' => 'application/json' } })
  end
end
