# frozen_string_literal: true

module UserProfileMock
  USERS = File.read('spec/fixtures/users.json')
  TOKEN = 'fake-user-access-token'

  def stub_user_info_api_for_unknown_users(user_id:)
    stub_user_info_api(user_id:, users: [])
  end

  def stub_user_info_api_for_owner(owner)
    stub_user_info_api_for(user_index: 0, user_id: owner.id)
  end

  def stub_user_info_api_for_teacher(teacher)
    stub_user_info_api_for(user_index: 1, user_id: teacher.id)
  end

  def stub_user_info_api_for_student(student)
    stub_user_info_api_for(user_index: 2, user_id: student.id)
  end

  def stub_user_info_api_for(user_index:, user_id:)
    user_attrs = user_attributes_by_index(user_index)
    user_attrs['id'] = user_id
    stub_user_info_api(user_id: user_attrs['id'], users: [user_attrs])
  end

  def authenticate_as_school_owner(school:, owner_id: SecureRandom.uuid)
    stub_hydra_public_api(user_index: 0, user_id: owner_id)
    create_owner_role(school:, owner_id:)
  end

  def authenticate_as_school_teacher(school:, teacher_id:)
    stub_hydra_public_api(user_index: 1, user_id: teacher_id)
    create_teacher_role(school:, teacher_id:)
  end

  def authenticate_as_school_student(school:, student_id:)
    stub_hydra_public_api(user_index: 2, user_id: student_id)
    create_student_role(school:, student_id:)
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

  def create_student_role(school:, student_id:)
    return if Role.student.exists?(user_id: student_id, school:)

    create(:student_role, user_id: student_id, school:)
  end

  def create_teacher_role(school:, teacher_id:)
    return unless School.exists?(id: school)
    return if Role.teacher.exists?(user_id: teacher_id, school:)

    create(:teacher_role, user_id: teacher_id, school:)
  end

  def create_owner_role(school:, owner_id:)
    return unless School.exists?(id: school)
    return if Role.owner.exists?(user_id: owner_id, school:)

    create(:owner_role, user_id: owner_id, school:)
  end
end
