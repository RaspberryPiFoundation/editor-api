# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a lesson', type: :request do
  before do
    stub_hydra_public_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  let(:params) do
    {
      lesson: {
        name: 'Test Lesson',
      }
    }
  end

  it 'responds 201 Created' do
    post("/api/lessons", headers:, params:)
    expect(response).to have_http_status(:created)
  end

#  it 'responds 201 Created when the user is a school-teacher' do
#    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
#
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
#    expect(response).to have_http_status(:created)
#  end
#
#  it 'responds with the class member JSON' do
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
#    data = JSON.parse(response.body, symbolize_names: true)
#
#    expect(data[:student_id]).to eq(student_id)
#  end
#
#  it 'responds with the student JSON' do
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
#    data = JSON.parse(response.body, symbolize_names: true)
#
#    expect(data[:student_name]).to eq('School Student')
#  end
#
#  it "responds with nil attributes for the student if their user profile doesn't exist" do
#    student_id = SecureRandom.uuid
#
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: { class_member: { student_id: } })
#    data = JSON.parse(response.body, symbolize_names: true)
#
#    expect(data[:student_name]).to be_nil
#  end
#
#  it 'responds 400 Bad Request when params are missing' do
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
#    expect(response).to have_http_status(:bad_request)
#  end
#
#  it 'responds 422 Unprocessable Entity when params are invalid' do
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: { class_member: { student_id: ' ' } })
#    expect(response).to have_http_status(:unprocessable_entity)
#  end
#
#  it 'responds 401 Unauthorized when no token is given' do
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", params:)
#    expect(response).to have_http_status(:unauthorized)
#  end
#
#  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
#    school = create(:school, id: SecureRandom.uuid)
#    school_class.update!(school_id: school.id)
#
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
#    expect(response).to have_http_status(:forbidden)
#  end
#
#  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
#    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
#    school_class.update!(teacher_id: SecureRandom.uuid)
#
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
#    expect(response).to have_http_status(:forbidden)
#  end
#
#  it 'responds 403 Forbidden when the user is a school-student' do
#    stub_hydra_public_api(user_index: user_index_by_role('school-student'))
#
#    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params:)
#    expect(response).to have_http_status(:forbidden)
#  end
end
