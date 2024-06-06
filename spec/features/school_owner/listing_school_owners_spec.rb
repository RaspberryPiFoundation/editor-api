# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school owners', type: :request do
  before do
    authenticate_as_school_owner(owner)
    stub_profile_api_list_school_owners(user_id: owner.id)
    stub_user_info_api_for(owner)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:, name: 'School Owner') }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticate_as_school_teacher(teacher)

    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school owners JSON' do
    get("/api/schools/#{school.id}/owners", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('School Owner')
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/owners"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticate_as_school_student(student)

    get("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
