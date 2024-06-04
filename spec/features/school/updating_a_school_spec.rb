# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a school', type: :request do
  before do
    authenticate_as_school_owner(school:, owner_id:)
  end

  let!(:school) { create(:school) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:owner_id) { SecureRandom.uuid }

  let(:params) do
    {
      school: {
        name: 'New Name'
      }
    }
  end

  it 'responds 200 OK' do
    put("/api/schools/#{school.id}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school JSON' do
    put("/api/schools/#{school.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds 404 Not Found when no school exists' do
    put('/api/schools/not-a-real-id', headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 400 Bad Request when params are missing' do
    put("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    put("/api/schools/#{school.id}", headers:, params: { school: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put "/api/schools/#{school.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is not a school-owner' do
    authenticate_as_school_teacher(school:)

    put("/api/schools/#{school.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner_id, school:).delete
    school.update!(id: SecureRandom.uuid)

    put("/api/schools/#{school.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
