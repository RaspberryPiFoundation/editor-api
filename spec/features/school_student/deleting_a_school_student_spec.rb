# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school student', type: :request do
  before do
    authenticate_as_school_owner(owner)
    stub_profile_api_delete_school_student
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student_id) { SecureRandom.uuid }
  let(:owner) { create(:owner, school:) }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/students/#{student_id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticate_as_school_teacher(teacher)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
