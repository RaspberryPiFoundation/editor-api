# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a school student', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_profile_api_school_student # Add missing stub for the SSO check
    stub_profile_api_update_school_student
    stub_profile_api_create_safeguarding_flag
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student_id) { SecureRandom.uuid }
  let(:owner) { create(:owner, school:) }

  let(:params) do
    {
      school_student: {
        username: 'new-username',
        password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
        name: 'New Name'
      }
    }
  end

  it 'creates the school owner safeguarding flag' do
    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email, school_id: school.id)
  end

  it 'does not create the school teacher safeguarding flag' do
    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: owner.email, school_id: school.id)
  end

  it 'responds 204 No Content' do
    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:no_content)
  end

  it 'does not create the school owner safeguarding flag when the user is a school teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email, school_id: school.id)
  end

  it 'creates the school teacher safeguarding flag when the user is a school teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: teacher.email, school_id: school.id)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/schools/#{school.id}/students/#{student_id}", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    put("/api/schools/#{school.id}/students/#{student_id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
