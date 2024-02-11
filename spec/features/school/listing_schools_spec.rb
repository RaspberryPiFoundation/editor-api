# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing schools that the current user belongs to', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api

    create(:school, name: 'Test School')
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:user_id) { stubbed_user_id }

  it 'responds 200 OK' do
    get('/api/schools', headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school JSON' do
    get('/api/schools', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School')
  end

  it 'only includes schools the user belongs to' do
    create(:school, organisation_id: '00000000-0000-0000-0000-000000000000', owner_id: '99999999-9999-9999-9999-999999999999')
    create(:school, organisation_id: '11111111-1111-1111-1111-111111111111', owner_id: '99999999-9999-9999-9999-999999999999')

    get('/api/schools', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get '/api/schools'
    expect(response).to have_http_status(:unauthorized)
  end
end
