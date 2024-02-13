# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing schools', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api

    create(:school, name: 'Test School')
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  it 'responds 200 OK' do
    get('/api/schools', headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the schools JSON' do
    get('/api/schools', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School')
  end

  it 'only includes schools the user belongs to' do
    create(:school, id: SecureRandom.uuid)

    get('/api/schools', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get '/api/schools'
    expect(response).to have_http_status(:unauthorized)
  end
end
