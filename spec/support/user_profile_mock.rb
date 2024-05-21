# frozen_string_literal: true

module UserProfileMock
  USERS = File.read('spec/fixtures/users.json')
  TOKEN = 'fake-user-access-token'

  def stub_user_info_api_for_unknown_users(user_id:)
    stub_user_info_api(user_id:, users: [])
  end

  def stub_user_info_api_for_owner(owner_id:, school_id:)
    stub_user_info_api_for(user_index: 0, user_id: owner_id, school_id:)
  end

  def stub_user_info_api_for_teacher(teacher_id:, school_id:)
    stub_user_info_api_for(user_index: 1, user_id: teacher_id, school_id:)
  end

  def stub_user_info_api_for_student(student_id:, school_id:)
    stub_user_info_api_for(user_index: 2, user_id: student_id, school_id:)
  end

  def stub_user_info_api_for_student_without_organisations(student_id:)
    stub_user_info_api_for(user_index: 3, user_id: student_id)
  end

  def stub_user_info_api_for(user_index:, user_id: nil, school_id: nil)
    user_attrs = user_attributes_by_index(user_index)
    user_attrs['id'] = user_id if user_id
    user_attrs['organisations'] = { school_id => user_attrs['roles'] } if school_id
    stub_user_info_api(user_id: user_attrs['id'], users: [user_attrs])
  end

  def authenticate_as_school_owner
    stub_hydra_public_api(user_index: 0)
  end

  def authenticate_as_school_teacher(teacher_id: SecureRandom.uuid)
    stub_hydra_public_api(user_index: 1, user_id: teacher_id)
  end

  def authenticate_as_school_student(student_id: SecureRandom.uuid)
    stub_hydra_public_api(user_index: 2, user_id: student_id)
  end

  def authenticate_as_school_student_without_organisations(student_id: SecureRandom.uuid)
    stub_hydra_public_api(user_index: 3, user_id: student_id)
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

  private

  # Stubs the API that returns user profile data for the logged in user.
  def stub_hydra_public_api(user_index:, user_id: nil)
    user_attrs = user_attributes_by_index(user_index)
    user_attrs['id'] = user_id if user_id

    stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo")
      .with(headers: { Authorization: "Bearer #{TOKEN}" })
      .to_return(
        status: 200,
        headers: { content_type: 'application/json' },
        body: user_attrs.to_json
      )
  end

  def stub_user_info_api(user_id:, users:)
    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" }, body: /#{user_id}/)
      .to_return({ body: { users: }.to_json, headers: { 'Content-Type' => 'application/json' } })
  end
end
