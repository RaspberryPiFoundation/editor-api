# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school', type: :request do
  before do
    authenticate_as_school_owner(school:, owner_id:)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner_id) { SecureRandom.uuid }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner_id, school:).delete
    school.update!(id: SecureRandom.uuid)

    delete("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    authenticate_as_school_teacher(school_id: school.id)

    delete("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student(school_id: school.id)

    delete("/api/schools/#{school.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
