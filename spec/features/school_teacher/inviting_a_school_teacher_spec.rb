# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inviting a school teacher', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_profile_api_invite_school_teacher
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, verified_at: Time.zone.now) }
  let(:teacher_id) { SecureRandom.uuid }
  let(:owner) { create(:owner, school:) }

  let(:params) do
    {
      school_teacher: {
        email_address: 'teacher-to-invite@example.com'
      }
    }
  end

  it 'responds 201 Created' do
    post("/api/schools/#{school.id}/teachers", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds 400 Bad Request when params are missing' do
    post("/api/schools/#{school.id}/teachers", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/teachers", headers:, params: { school_teacher: { email_address: 'invalid' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/teachers", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/teachers", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    post("/api/schools/#{school.id}/teachers", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    post("/api/schools/#{school.id}/teachers", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
