# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile auth check API' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }

  identity_url = "#{ENV.fetch('IDENTITY_URL')}/api/v1/access"

  describe 'GET /api/profile_auth_check' do
    context 'when the profile API authorises the current user' do
      it 'returns can_use_profile_api: true' do
        # Arrange
        authenticated_in_hydra_as(student)
        stub_request(:get, identity_url).to_return(status: 200, headers:)

        # Act
        get '/api/profile_auth_check', headers: headers

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => true)
      end
    end

    context 'when the profile API returns unauthorized' do
      it 'returns can_use_profile_api: false' do
        # Arrange
        authenticated_in_hydra_as(student)
        stub_request(:get, identity_url).to_return(status: 401, headers:)

        # Act
        get '/api/profile_auth_check', headers: headers

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => false)
      end
    end

    context 'when there is no current user' do
      it 'returns can_use_profile_api: false' do
        # Arrange
        stub_request(:get, identity_url).to_return(status: 400, headers:)

        # Act
        get '/api/profile_auth_check'

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => false)
      end
    end
  end
end
