# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing my school', type: :request do
  before do
    authenticated_in_hydra_as(owner)
  end

  let!(:school) { create(:school, name: 'school-name') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:owner) { create(:owner, school:) }

  it 'responds 200 OK' do
    get('/api/school', headers:)
    expect(response).to have_http_status(:ok)
  end

  it "includes the school details and user's roles in the JSON" do
    school_json = school.to_json(only: %i[id name website reference address_line_1 address_line_2 municipality administrative_area postal_code country_code verified_at created_at updated_at])
    expected_data = JSON.parse(school_json, symbolize_names: true).merge(roles: ['owner'])

    get('/api/school', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to eq(expected_data)
  end

  it "responds 404 Not Found when the user doesn't have a role in any school" do
    Role.find_by(school:, user_id: owner.id).delete
    get('/api/school', headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get '/api/school'
    expect(response).to have_http_status(:unauthorized)
  end
end
