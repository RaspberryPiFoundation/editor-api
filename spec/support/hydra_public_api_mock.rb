# frozen_string_literal: true

module HydraPublicApiMock
  USERS = File.read('spec/fixtures/users.json')

  def stub_fetch_oauth_user(user_index: 0)
    attributes = stubbed_user_attributes(user_index:)
    allow(HydraPublicApiClient).to receive(:fetch_oauth_user).and_return(attributes)
  end

  def stubbed_user_attributes(user_index: 0)
    return nil unless user_index

    attributes = JSON.parse(USERS)['users'][user_index]
    attributes['sub'] = attributes.delete('id')
    attributes
  end

  def stubbed_user_id(user_index: 0)
    stubbed_user_attributes(user_index:)&.fetch('sub')
  end

  def stubbed_user
    User.from_omniauth(token: 'ignored')
  end
end
