# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile auth check API' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:student) { create(:student, school:) }
  let(:user_without_student_role) { create(:user, roles: nil) }
  let(:api_url) { 'http://example.com' }
  let(:api_key) { 'api-key' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('IDENTITY_URL').and_return(api_url)
    allow(ENV).to receive(:fetch).with('PROFILE_API_KEY').and_return(api_key)
  end

  describe 'GET /api/profile_auth_check' do
    context 'when the profile API authorises the current user' do
      it 'returns can_use_profile_api: true' do
        # Arrange
        authenticated_in_hydra_as(teacher)
        stub_request(:get, "#{ENV.fetch('IDENTITY_URL')}/api/v1/access").to_return(status: 200, headers:)

        # Act
        get '/api/profile_auth_check', headers: headers

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => true)
      end
    end

    context 'when the current user is a student' do
      it 'returns can_use_profile_api: false without calling profile API' do
        # Arrange
        authenticated_in_hydra_as(student)
        profile_api_request = stub_request(:get, "#{ENV.fetch('IDENTITY_URL')}/api/v1/access")

        # Act
        get '/api/profile_auth_check', headers: headers

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => false)
        expect(profile_api_request).not_to have_been_requested
      end
    end

    context 'when the current user is a student identified by Hydra subject' do
      it 'returns can_use_profile_api: false without calling profile API' do
        # Arrange
        authenticated_in_hydra_as(user_without_student_role, :student)
        profile_api_request = stub_request(:get, "#{ENV.fetch('IDENTITY_URL')}/api/v1/access")

        # Act
        get '/api/profile_auth_check', headers: headers

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => false)
        expect(profile_api_request).not_to have_been_requested
      end
    end

    context 'when the profile API returns unauthorized for a non-student user' do
      it 'returns can_use_profile_api: false' do
        # Arrange
        authenticated_in_hydra_as(teacher)
        stub_request(:get, "#{ENV.fetch('IDENTITY_URL')}/api/v1/access").to_return(status: 401, headers:)

        # Act
        get '/api/profile_auth_check', headers: headers

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => false)
      end
    end

    context 'when there is no current user' do
      it 'returns can_use_profile_api: false without calling profile API' do
        # Arrange
        profile_api_request = stub_request(:get, "#{ENV.fetch('IDENTITY_URL')}/api/v1/access")

        # Act
        get '/api/profile_auth_check'

        # Assert
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('can_use_profile_api' => false)
        expect(profile_api_request).not_to have_been_requested
      end
    end
  end
end
