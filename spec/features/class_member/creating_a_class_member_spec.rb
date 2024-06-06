# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a class member', type: :request do
  before do
    authenticate_as_school_owner(school:)
    stub_user_info_api_for_teacher(teacher_id:, school:)
    stub_user_info_api_for_student(student)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_id:, school:) }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher_id) { SecureRandom.uuid }

  let(:params) do
    {
      class_member: {
        student_id: student.id
      }
    }
  end

  it 'responds 201 Created' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds 201 Created when the user is a school-teacher' do
    authenticate_as_school_teacher(teacher_id:, school:)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the class member JSON' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:student_id]).to eq(student.id)
  end

  it 'responds with the student JSON' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:student_name]).to eq('School Student')
  end

  # rubocop:disable RSpec/ExampleLength
  it "responds with nil attributes for the student if their user profile doesn't exist" do
    student_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id: student_id)
    new_params = { class_member: params[:class_member].merge(student_id:) }

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: new_params)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:student_name]).to be_nil
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 400 Bad Request when params are missing' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: { class_member: { student_id: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  # rubocop:disable RSpec/ExampleLength
  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id: teacher_id)
    authenticate_as_school_teacher(school:)
    school_class.update!(teacher_id:)
    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student(school:)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
