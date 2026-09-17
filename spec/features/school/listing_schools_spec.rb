# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing schools', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, name: 'Test School') }

  it 'responds 401 Unauthorized when no token is given' do
    get '/api/schools'
    expect(response).to have_http_status(:unauthorized)
  end

  context 'when the user is a school owner' do
    let(:user) { create(:owner, school:) }

    before do
      authenticated_in_hydra_as(user)
    end

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

  it 'creates a student role when the students token includes a school claim but they have no school already' do
    user = build(:student, school_id: school.id)
    authenticated_in_hydra_as(user, :student)

    expect { get('/api/schools', headers:) }
      .to change { Role.student.where(school:, user_id: user.id).count }.by(1)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School')
  end
end
