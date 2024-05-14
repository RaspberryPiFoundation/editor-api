# frozen_string_literal: true

module UserProfileMock
  USERS = File.read('spec/fixtures/users.json')
  TOKEN = 'fake-user-access-token'

  # Stubs that API that returns user profile data for a given list of UUIDs.
  def stub_user_info_api
    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" })
      .to_return do |request|
        uuids = JSON.parse(request.body).fetch('userIds', [])
        indexes = uuids.map { |uuid| user_index_by_uuid(uuid) }.compact
        users = indexes.map { |user_index| user_attributes_by_index(user_index) }

        { body: { users: }.to_json, headers: { 'Content-Type' => 'application/json' } }
      end
  end

  def stub_user_info_api_for_class_member(class_member)
    index = user_index_by_role('school-student')
    attrs = user_attributes_by_index(index)
    attrs[:id] = class_member.student_id

    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" })
      .to_return({ body: { users: [attrs] }.to_json, headers: { 'Content-Type' => 'application/json' } })
  end

  def stub_user_info_api_for_school_class(school_class)
    index = user_index_by_role('school-teacher')
    attrs = user_attributes_by_index(index)
    attrs[:id] = school_class.teacher_id

    stub_request(:get, "#{UserInfoApiClient::API_URL}/users")
      .with(headers: { Authorization: "Bearer #{UserInfoApiClient::API_KEY}" })
      .to_return({ body: { users: [attrs] }.to_json, headers: { 'Content-Type' => 'application/json' } })
  end

  def authenticate_as_school_owner
    stub_hydra_public_api(user_index: 0)
  end

  def authenticate_as_school_teacher(teacher_id: nil)
    stub_hydra_public_api(user_index: 1, user_id: teacher_id)
  end

  def authenticate_as_school_student(member = nil)
    if member
      stub_hydra_public_api_for_class_member(member)
    else
      stub_hydra_public_api(user_index: 2)
    end
  end

  def authenticate_as_school_student_without_organisations
    stub_hydra_public_api(user_index: 3)
  end

  def unauthenticated_user
    stub_hydra_public_api(user_index: nil)
  end

  def stub_hydra_public_api_for_class_member(class_member, token: TOKEN)
    index = user_index_by_role('school-student')
    attrs = user_attributes_by_index(index)
    attrs[:id] = class_member.student_id

    body = attrs.to_json

    stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo")
      .with(headers: { Authorization: "Bearer #{token}" })
      .to_return(
        status: 200,
        headers: { content_type: 'application/json' },
        body:
      )
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
  def stub_hydra_public_api(user_index:, user_id: nil)
    attrs = user_attributes_by_index(user_index)
    attrs[:id] = user_id if user_id

    body = attrs.to_json

    stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo")
      .with(headers: { Authorization: "Bearer #{TOKEN}" })
      .to_return(
        status: 200,
        headers: { content_type: 'application/json' },
        body:
      )
  end
end
