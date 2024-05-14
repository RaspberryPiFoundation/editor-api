# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a school class', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, name: 'Test School Class') }
  let(:school) { school_class.school }
  let(:teacher_index) { user_index_by_role('school-teacher') }
  let(:teacher_id) { user_id_by_index(teacher_index) }

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

  it 'responds 200 OK when the user is the school-teacher for the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school class JSON' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds with the teacher JSON' do
    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to eq('School Teacher')
  end

  it "responds with nil attributes for the teacher if their user profile doesn't exist" do
    teacher_id = SecureRandom.uuid
    new_params = { school_class: params[:school_class].merge(teacher_id:) }

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params: new_params)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to be_nil
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

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
    school_class.update!(teacher_id: SecureRandom.uuid)

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
