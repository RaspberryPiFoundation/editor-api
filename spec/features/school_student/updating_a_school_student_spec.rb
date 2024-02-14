# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a school student', type: :request do
  before do
    stub_hydra_public_api
    stub_profile_api_update_school_student
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  let(:params) do
    {
      school_student: {
        username: 'new-username',
        password: 'new-password',
        name: 'New Name'
      }
    }
  end

  it 'responds 204 No Content' do
    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/schools/#{school.id}/students/#{student_id}", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
