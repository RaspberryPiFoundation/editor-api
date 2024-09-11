# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school teachers', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:teacher_2) { create(:teacher, school:) }

  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(teacher)
  end

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:ok)
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
    authenticated_in_hydra_as(student)

    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 200 OK when the user is a school-teacher' do
    stub_user_info_api_for_users([teacher.id, teacher_2.id], users: [teacher, teacher_2])
    authenticated_in_hydra_as(teacher_2)

    get("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school teachers JSON' do
    stub_user_info_api_for_users([teacher.id, teacher_2.id], users: [teacher, teacher_2])
    authenticated_in_hydra_as(teacher_2)

    get("/api/schools/#{school.id}/teachers", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.pluck(:name)).to include(teacher_2.name)
  end
end
