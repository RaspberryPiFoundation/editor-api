# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school student', type: :request do
  before do
    stub_hydra_public_api
    stub_profile_api_delete_school_student
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/students/#{student_id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
