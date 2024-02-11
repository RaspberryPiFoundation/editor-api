# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a school', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:user_id) { stubbed_user_id }

  let(:params) do
    {
      school: {
        name: 'Test School',
        address_line_1: 'Address Line 1', # rubocop:disable Naming/VariableNumber
        municipality: 'Greater London',
        country_code: 'GB'
      }
    }
  end

  before do
    stub_hydra_public_api
    stub_user_info_api
    stub_profile_api_create_organisation
  end

  it 'responds 201 Created' do
    post('/api/schools', headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the school JSON' do
    post('/api/schools', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test School')
  end

  it 'responds 400 Bad Request when params are missing' do
    post('/api/schools', headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post('/api/schools', headers:, params: { school: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post '/api/schools'
    expect(response).to have_http_status(:unauthorized)
  end
end
