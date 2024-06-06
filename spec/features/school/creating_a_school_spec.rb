# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a school', type: :request do
  before do
    authenticate_as_school_owner(owner)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }

  let(:params) do
    {
      school: {
        name: 'Test School',
        website: 'http://www.example.com',
        address_line_1: 'Address Line 1',
        municipality: 'Greater London',
        country_code: 'GB',
        creator_agree_authority: true,
        creator_agree_terms_and_conditions: true
      }
    }
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
