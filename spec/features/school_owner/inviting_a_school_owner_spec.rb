# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inviting a school owner', type: :request do
  before do
    authenticate_as_school_owner(school:, owner_id:)
    stub_profile_api_invite_school_owner
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, verified_at: Time.zone.now) }
  let(:owner_id) { SecureRandom.uuid }

  let(:params) do
    {
      school_owner: {
        email_address: 'owner-to-invite@example.com'
      }
    }
  end

  it 'responds 201 Created' do
    post("/api/schools/#{school.id}/owners", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds 400 Bad Request when params are missing' do
    post("/api/schools/#{school.id}/owners", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/owners", headers:, params: { school_owner: { email_address: 'invalid' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/owners", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner_id, school:).delete
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/owners", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    authenticate_as_school_teacher(school:)

    post("/api/schools/#{school.id}/owners", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student(school:)

    post("/api/schools/#{school.id}/owners", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
