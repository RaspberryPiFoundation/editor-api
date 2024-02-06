# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a school', type: :request do
  let(:user_id) { '11111111-11111111-11111111-11111111' }
  let(:headers) { { Authorization: 'dummy-token' } }

  let(:params) do
    {
      name: 'Test School',
      organisation_id: '00000000-00000000-00000000-00000000',
      address_line_1: 'Address Line 1', # rubocop:disable Naming/VariableNumber
      municipality: 'Greater London',
      country_code: 'GB'
    }
  end

  before do
    stub_fetch_oauth_user_id(user_id)
  end

  it 'responds 200 OK' do
    post('/api/schools', headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school JSON' do
    post('/api/schools', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test School')
  end

  it "assigns the current user as the school's owner" do
    post('/api/schools', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:owner_id]).to eq(user_id)
  end

  it 'responds 400 Bad Request when params are missing' do
    post('/api/schools', headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post('/api/schools', headers:, params: { name: ' ' })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post '/api/schools'
    expect(response).to have_http_status(:unauthorized)
  end
end
