# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a school student', type: :request do
  before do
    authenticate_as_school_owner(school:, owner_id:)
    stub_profile_api_create_school_student
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, verified_at: Time.zone.now) }
  let(:owner_id) { SecureRandom.uuid }

  let(:params) do
    {
      school_student: {
        username: 'student123',
        password: 'at-least-8-characters',
        name: 'School Student'
      }
    }
  end

  it 'responds 204 No Content' do
    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is a school-teacher' do
    authenticate_as_school_teacher(school:, teacher_id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:no_content)
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
    Role.owner.find_by(user_id: owner_id, school:).delete
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student(school:, student_id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/students", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
