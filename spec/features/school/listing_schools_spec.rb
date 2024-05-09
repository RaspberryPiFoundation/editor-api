# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing schools', type: :request do
  before do
    stub_hydra_public_api(user_index: school_owner_index)

    school = create(:school, name: 'Test School')
    create(:owner_role, school:, user_id: school_owner_id)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school_owner_index) { user_index_by_role('school-owner') }
  let(:school_owner_id) { user_id_by_index(school_owner_index) }

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
