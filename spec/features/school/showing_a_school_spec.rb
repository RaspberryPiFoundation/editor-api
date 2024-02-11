# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a school', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api
  end

  let!(:school) { create(:school, name: 'Test School') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:user_id) { stubbed_user_id }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school JSON' do
    get("/api/schools/#{school.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test School')
  end

  it 'responds 404 Not Found when no school exists' do
    get('/api/schools/not-a-real-id', headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user belongs to a different school' do
    school.update!(organisation_id: '00000000-00000000-00000000-00000000')

    get("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
