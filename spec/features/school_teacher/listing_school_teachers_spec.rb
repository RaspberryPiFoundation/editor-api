# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school teachers', type: :request do
  before do
    authenticate_as_school_owner(owner)
    stub_profile_api_list_school_teachers(user_id: teacher.id)
    stub_user_info_api_for(teacher)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticate_as_school_teacher(teacher)

    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school teachers JSON' do
    get("/api/schools/#{school.id}/teachers", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('School Teacher')
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/teachers"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.teacher.find_by(user_id: teacher.id, school:).delete
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticate_as_school_student(student)

    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
