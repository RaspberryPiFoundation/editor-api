# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a school class', type: :request do
  before do
    authenticate_as_school_owner(owner)
    stub_user_info_api_for_teacher(teacher)
  end

  let!(:school_class) { create(:school_class, name: 'Test School Class', teacher_id: teacher.id, school:) }
  let(:school) { create(:school) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is the class teacher' do
    authenticate_as_school_teacher(teacher)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  # rubocop:disable RSpec/ExampleLength
  it 'responds 200 OK when the user is a student in the class' do
    student = create(:student, school:)
    stub_user_info_api_for(student)
    authenticate_as_school_student(student)
    create(:class_member, school_class:, student_id: student.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:ok)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds with the school class JSON' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test School Class')
  end

  it 'responds with the teacher JSON' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to eq('School Teacher')
  end

  # rubocop:disable RSpec/ExampleLength
  it "responds with nil attributes for the teacher if their user profile doesn't exist" do
    teacher_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id: teacher_id)
    school_class.update!(teacher_id:)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to be_nil
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 404 Not Found when no school exists' do
    get("/api/schools/not-a-real-id/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 404 Not Found when no school class exists' do
    get("/api/schools/#{school.id}/classes/not-a-real-id", headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes/#{school_class.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher = create(:teacher, school:)
    authenticate_as_school_teacher(teacher)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not a school-student for the class' do
    student = create(:student, school:)
    authenticate_as_school_student(student)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
