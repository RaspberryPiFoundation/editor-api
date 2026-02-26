# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school student', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_profile_api_delete_school_student
    stub_profile_api_create_safeguarding_flag
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student_id) { SecureRandom.uuid }
  let(:owner) { create(:owner, school:) }

  it 'calls ProfileApiClient to delete the student from the profile service' do
    student = create(:student, school:)
    delete("/api/schools/#{school.id}/students/#{student.id}", headers:)
    expect(ProfileApiClient).to have_received(:delete_school_student).with(token: UserProfileMock::TOKEN, school_id: school.id, student_id: student.id)
  end

  it 'creates the school owner safeguarding flag' do
    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email, school_id: school.id)
  end

  it 'does not create the school teacher safeguarding flag' do
    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: owner.email, school_id: school.id)
  end

  it 'responds 200 OK' do
    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:ok)
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
    authenticated_in_hydra_as(teacher)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'does not create the school owner safeguarding flag when logged in as a teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email, school_id: school.id)
  end

  it 'does not create the school teacher safeguarding flag when logged in as a teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: teacher.email, school_id: school.id)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    delete("/api/schools/#{school.id}/students/#{student_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
