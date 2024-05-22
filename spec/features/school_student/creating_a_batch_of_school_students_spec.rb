# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a batch of school students', type: :request do
  before do
    authenticate_as_school_owner(school_id: school.id)
    stub_profile_api_create_school_student
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, verified_at: Time.zone.now) }
  let(:student_id) { SecureRandom.uuid }

  let(:file) { fixture_file_upload('students.csv') }

  it 'responds 204 No Content' do
    post("/api/schools/#{school.id}/students/batch", headers:, params: { file: })
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is a school-teacher' do
    authenticate_as_school_teacher(school_id: school.id)

    post("/api/schools/#{school.id}/students/batch", headers:, params: { file: })
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/students/batch", headers:, params: {})
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/students/batch", params: { file: })
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/students/batch", headers:, params: { file: })
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student

    post("/api/schools/#{school.id}/students/batch", headers:, params: { file: })
    expect(response).to have_http_status(:forbidden)
  end
end
