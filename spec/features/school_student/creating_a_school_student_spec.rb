# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a school student', type: :request do
  before do
    stub_hydra_public_api
    stub_profile_api_create_school_student(user_id: student_id)
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  let(:params) do
    {
      school_student: {
        username: 'student123',
        password: 'at-least-8-characters',
        name: 'School Student'
      }
    }
  end

  it 'responds 201 Created' do
    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds 201 Created when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the created student JSON' do
    post("/api/schools/#{school.id}/students", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('School Student')
  end

  it 'responds 400 Bad Request when params are missing' do
    post("/api/schools/#{school.id}/students", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/students", headers:, params: { school_student: { username: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/students", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end