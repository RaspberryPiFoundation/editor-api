# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Removing a school teacher', type: :request do
  before do
    stub_hydra_public_api(user_index: owner_index)
    stub_profile_api_remove_school_teacher
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher_index) { user_index_by_role('school-teacher') }
  let(:teacher_id) { user_id_by_index(teacher_index) }
  let(:owner_index) { user_index_by_role('school-owner') }
  let(:owner_id) { user_id_by_index(owner_index) }
  let!(:role) { create(:owner_role, school:, user_id: owner_id) }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/teachers/#{teacher_id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/teachers/#{teacher_id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    different_school = create(:school, id: SecureRandom.uuid)
    role.update!(school: different_school)

    delete("/api/schools/#{school.id}/teachers/#{teacher_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    delete("/api/schools/#{school.id}/teachers/#{teacher_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    delete("/api/schools/#{school.id}/teachers/#{teacher_id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
