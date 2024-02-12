# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a school class', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, name: 'Test School Class') }
  let(:school) { school_class.school }
  let(:teacher_index) { user_index_by_role('school-teacher') }
  let(:teacher_id) { stubbed_user_id(user_index: teacher_index) }

  let(:params) do
    {
      school_class: {
        name: 'New Name'
      }
    }
  end

  it 'responds 200 OK' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school class JSON' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds 400 Bad Request when params are missing' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params: { school_class: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is not a school-owner or school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
    school_class.update!(teacher_id: '99999999-99999999-99999999-99999999')

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(organisation_id: '00000000-00000000-00000000-00000000')

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
