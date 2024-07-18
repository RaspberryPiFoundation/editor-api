# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing class members', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    student_attributes = students.map do |student|
      { id: student.id, name: student.name, username: student.username }
    end
    stub_profile_api_list_school_students(school:, student_attributes:)
    students.each do |student|
      create(:class_member, student_id: student.id, school_class: school_class)
    end
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school_class) { build(:school_class, teacher_id: teacher.id, school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the class members JSON array' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(3)
  end

  it 'responds with the correct student_ids' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    student_ids_from_response = data.map { |member| member[:student_id] }
    expected_student_ids = students.map(&:id)

    expect(student_ids_from_response).to match_array(expected_student_ids)
  end

  it 'responds with the correct nested student ids' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    student_ids_from_response = data.map { |member| member[:student][:id] }
    expected_student_ids = students.map(&:id)

    expect(student_ids_from_response).to match_array(expected_student_ids)
  end

  it 'responds with the students JSON' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    student_names_from_response = data.map { |member| member[:student][:name] }
    expected_student_names = students.map(&:name)

    expect(student_names_from_response).to match_array(expected_student_names)
  end

  it "responds with nil attributes for students if the user profile doesn't exist" do
    stub_user_info_api_for_unknown_users(user_id: students.first.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:student_name]).to be_nil
  end

  # rubocop:disable RSpec/ExampleLength
  it 'does not include class members that belong to a different class' do
    student = create(:student, school:)
    different_class = create(:school_class, school:, teacher_id: teacher.id)
    create(:class_member, school_class: different_class, student_id: student.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(3)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes/#{school_class.id}/members"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
