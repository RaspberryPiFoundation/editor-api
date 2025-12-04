# frozen_string_literal: true

module UserInfoApiMock
  def stub_user_info_api_fetch_by_ids(user_ids:, users: [])
    users = default_stubbed_users(user_ids) if users.empty?

    allow(UserInfoApiClient).to receive(:fetch_by_ids)
      .with(user_ids)
      .and_return(users)
  end

  def stub_user_info_api_find_by_email(email:, user: :not_provided)
    user = default_stubbed_user_by_email(email) if user == :not_provided

    allow(UserInfoApiClient).to receive(:find_user_by_email)
      .with(email)
      .and_return(user)
  end

  private

  def default_stubbed_users(user_ids)
    user_ids.map { |user_id| default_stubbed_user(id: user_id, email: "user-#{user_id}@example.com") }
  end

  def default_stubbed_user_by_email(email)
    default_stubbed_user(
      id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, email),
      email: email
    )
  end

  def default_stubbed_user(id:, email:)
    {
      id: id,
      email: email,
      username: nil,
      parental_email: nil,
      name: 'School Owner',
      nickname: 'Owner',
      country: 'United Kingdom',
      country_code: 'GB',
      postcode: nil,
      date_of_birth: nil,
      verified_at: '2024-01-01T12:00:00.000Z',
      created_at: '2024-01-01T12:00:00.000Z',
      updated_at: '2024-01-01T12:00:00.000Z',
      discarded_at: nil,
      last_logged_in_at: '2024-01-01T12:00:00.000Z',
      roles: ''
    }
  end
end
