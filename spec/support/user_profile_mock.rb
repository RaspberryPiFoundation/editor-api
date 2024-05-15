# frozen_string_literal: true

module UserProfileMock
  USERS = File.read('spec/fixtures/users.json')
  TOKEN = 'fake-user-access-token'

  # Stubs that API that returns user profile data for a given list of UUIDs.
  def stub_user_info_api
    stub_user_info_api_for_unknown_users
    stub_user_info_api_for_owner
  end

  def stub_user_info_api_for_unknown_users
    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" })
      .to_return({ body: { users: [] }.to_json, headers: { 'Content-Type' => 'application/json' } })
  end

  def stub_user_info_api_for_owner
    stub_user_info_api_for(user_index: 0)
  end

  def stub_user_info_api_for_teacher
    stub_user_info_api_for(user_index: 1)
  end

  def stub_user_info_api_for_student
    stub_user_info_api_for(user_index: 2)
  end

  def stub_user_info_api_for_student_without_organisations
    stub_user_info_api_for(user_index: 3)
  end

  def stub_user_info_api_for(user_index:)
    user_attrs = user_attributes_by_index(user_index)

    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" }, body: /#{user_attrs['id']}/)
      .to_return({ body: { users: [user_attrs] }.to_json, headers: { 'Content-Type' => 'application/json' } })
  end

  def authenticate_as_school_owner
    stub_hydra_public_api(user_index: 0)
  end

  def authenticate_as_school_teacher
    stub_hydra_public_api(user_index: 1)
  end

  def authenticate_as_school_student
    stub_hydra_public_api(user_index: 2)
  end

  def authenticate_as_school_student_without_organisations
    stub_hydra_public_api(user_index: 3)
  end

  def unauthenticated_user
    stub_hydra_public_api(user_index: nil)
  end

  def stubbed_user
    User.from_token(token: TOKEN)
  end

  def user_attributes_by_index(user_index = 0)
    JSON.parse(USERS)['users'][user_index] if user_index
  end

  def user_id_by_index(user_index)
    user_attributes_by_index(user_index)&.fetch('id')
  end

  def user_index_by_uuid(uuid)
    JSON.parse(USERS)['users'].find_index { |attr| attr['id'] == uuid }
  end

  def user_index_by_role(name)
    JSON.parse(USERS)['users'].find_index { |attr| attr['roles'].include?(name) }
  end

  private

  # Stubs the API that returns user profile data for the logged in user.
  def stub_hydra_public_api(user_index:)
    stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo")
      .with(headers: { Authorization: "Bearer #{TOKEN}" })
      .to_return(
        status: 200,
        headers: { content_type: 'application/json' },
        body: user_attributes_by_index(user_index).to_json
      )
  end
end
