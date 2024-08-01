# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school students', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    student_attributes = [{ id: student.id, name: 'School Student' }]
    stub_profile_api_list_school_students(school:, student_attributes:)
    stub_profile_api_create_safeguarding_flag
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:owner) { create(:owner, school:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/students", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'creates the school owner safeguarding flag' do
    get("/api/schools/#{school.id}/students", headers:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email)
  end

  it 'does not create the school teacher safeguarding flag' do
    get("/api/schools/#{school.id}/students", headers:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: owner.email)
  end

  it 'responds 200 OK when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    get("/api/schools/#{school.id}/students", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'does not create the school owner safeguarding flag when the user is a school teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    get("/api/schools/#{school.id}/students", headers:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email)
  end

  it 'creates the school teacher safeguarding flag when the user is a school teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    get("/api/schools/#{school.id}/students", headers:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: teacher.email)
  end

  it 'responds with the school students JSON' do
    get("/api/schools/#{school.id}/students", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('School Student')
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/students"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.student.find_by(user_id: student.id, school:).delete
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/students", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    get("/api/schools/#{school.id}/students", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
