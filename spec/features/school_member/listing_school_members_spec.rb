# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school members', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:students) { create_list(:student, 3, school:) }

  before do
    authenticated_in_hydra_as(owner)

    student_attributes = students.map do |student|
      { id: student.id, name: student.name, username: student.username }
    end
    stub_profile_api_list_school_students(school:, student_attributes:)
    stub_user_info_api_for(teacher)
    stub_profile_api_create_safeguarding_flag
  end

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/members", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school members JSON array' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(5)
  end

  it 'responds with the correct student ids' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    student_ids = data.pluck(:student).compact.pluck(:id)

    students.each do |student|
      expect(student_ids).to include(student.id)
    end
  end

  it 'responds with the expected student parameters' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    student_data = data.pluck(:student).compact.find { |member| member[:id] == students[0].id }

    expect(student_data).to eq(
      {
        id: students[0].id,
        username: students[0].username,
        name: students[0].name,
        type: 'student'
      }
    )
  end

  it 'responds with the correct teacher id' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    teacher_id = data.pluck(:teacher).compact.pick(:id)

    expect(teacher_id).to eq(teacher.id)
  end

  it 'responds with the expected teacher parameters' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    teacher_data = data.pluck(:teacher).compact

    expect(teacher_data.first).to eq(
      {
        id: teacher.id,
        name: teacher.name,
        email: teacher.email,
        type: 'teacher'
      }
    )
  end

  it 'responds with owners at the top' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[0][:owner]).to be_truthy
  end

  it 'responds with teachers second from the top' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[1][:teacher]).to be_truthy
  end

  it 'responds with students after owners and teachers' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[2][:student]).to be_truthy
  end

  it 'responds with students in alphabetical order by name ascending' do
    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    student_names = data.pluck(:student).compact.pluck(:name)
    sorted_student_names = student_names.sort

    expect(student_names).to eq(sorted_student_names)
  end

  it 'creates the school owner safeguarding flag' do
    get("/api/schools/#{school.id}/students", headers:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email)
  end

  it 'does not create the school teacher safeguarding flag' do
    get("/api/schools/#{school.id}/students", headers:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: owner.email)
  end

  it "responds with nil attributes for students if the user profile doesn't exist" do
    stub_user_info_api_for_unknown_users(user_id: students.first.id)

    get("/api/schools/#{school.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:student_name]).to be_nil
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/members"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    get("/api/schools/#{school.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
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
end
