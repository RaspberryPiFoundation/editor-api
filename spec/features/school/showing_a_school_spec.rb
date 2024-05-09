# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a school', type: :request do
  before do
    stub_hydra_public_api(user_index: owner_index)
  end

  let!(:school) { create(:school, name: 'Test School') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:owner_index) { user_index_by_role('school-owner') }
  let(:owner_id) { user_id_by_index(owner_index) }
  let!(:role) { create(:owner_role, school:, user_id: owner_id) }

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
    different_school = create(:school, id: SecureRandom.uuid)
    role.update!(school: different_school)

    get("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
