# frozen_string_literal: true

module UserProfileMock
  USERS = File.read('spec/fixtures/users.json')
  TOKEN = 'fake-user-access-token'

  def stub_user_info_api_for_unknown_users(user_id:)
    stub_user_info_api(user_id:, users: [])
  end

  def stub_user_info_api_for(user)
    stub_user_info_api(user_id: user.id, users: [user_to_hash(user)])
  end

  def authenticate_as_school_owner(owner)
    user = user_attributes_by_index(0)
    user['id'] = owner.id

    stub_hydra_public_api(user)
  end

  def authenticate_as_school_teacher(teacher)
    user = user_attributes_by_index(1)
    user['id'] = teacher.id

    stub_hydra_public_api(user)
  end

  def authenticate_as_school_student(student)
    user = user_attributes_by_index(2)
    user['id'] = student.id

    stub_hydra_public_api(user)
  end

  def unauthenticated_user
    stub_hydra_public_api({})
  end

  def stubbed_user
    User.from_token(token: TOKEN)
  end

  def user_attributes_by_index(user_index = 0)
    JSON.parse(USERS)['users'][user_index] if user_index
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
