# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school class', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class) }
  let(:school) { school_class.school }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is the class teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/classes/#{school_class.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
    school_class.update!(teacher_id: SecureRandom.uuid)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
