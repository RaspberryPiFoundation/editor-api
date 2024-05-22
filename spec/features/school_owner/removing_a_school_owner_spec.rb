# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Removing a school owner', type: :request do
  before do
    authenticate_as_school_owner(school_id: school.id)
    stub_profile_api_remove_school_owner
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school, id: School::ID) }
  let(:owner_id) { User::OWNER_ID }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/owners/#{owner_id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/owners/#{owner_id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    delete("/api/schools/#{school.id}/owners/#{owner_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    authenticate_as_school_teacher

    delete("/api/schools/#{school.id}/owners/#{owner_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student

    delete("/api/schools/#{school.id}/owners/#{owner_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
