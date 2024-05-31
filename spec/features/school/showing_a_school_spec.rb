# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a school', type: :request do
  before do
    authenticate_as_school_owner(school_id: school.id, owner_id:)
  end

  let!(:school) { create(:school, name: 'Test School') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:owner_id) { SecureRandom.uuid }

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
    Role.owner.find_by(user_id: owner_id, school:).delete
    school.update!(id: SecureRandom.uuid)

    get("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
