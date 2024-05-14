# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a batch of school students', type: :request do
  before do
    authenticate_as_school_owner
    stub_profile_api_create_school_student
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, verified_at: Time.zone.now) }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  let(:file) { fixture_file_upload('students.csv') }

  it 'responds 204 No Content' do
    post("/api/schools/#{school.id}/students/batch", headers:, params: { file: })
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

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
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    post("/api/schools/#{school.id}/students/batch", headers:, params: { file: })
    expect(response).to have_http_status(:forbidden)
  end
end
