# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school owners', type: :request do
  before do
    stub_hydra_public_api
    stub_profile_api_list_school_owners(user_id: owner_id)
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner_index) { user_index_by_role('school-owner') }
  let(:owner_id) { user_id_by_index(owner_index) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school owners JSON' do
    get("/api/schools/#{school.id}/owners", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('School Owner')
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/owners"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
