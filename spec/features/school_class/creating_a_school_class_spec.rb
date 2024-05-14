# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a school class', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher_index) { user_index_by_role('school-teacher') }
  let(:teacher_id) { user_id_by_index(teacher_index) }

  let(:params) do
    {
      school_class: {
        name: 'Test School Class',
        teacher_id:
      }
    }
  end

  it 'responds 201 Created' do
    post("/api/schools/#{school.id}/classes", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds 201 Created when the user is a school-teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    post("/api/schools/#{school.id}/classes", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the school class JSON' do
    post("/api/schools/#{school.id}/classes", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test School Class')
  end

  it 'responds with the teacher JSON' do
    post("/api/schools/#{school.id}/classes", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to eq('School Teacher')
  end

  it "responds with nil attributes for the teacher if their user profile doesn't exist" do
    teacher_id = SecureRandom.uuid
    new_params = { school_class: params[:school_class].merge(teacher_id:) }

    post("/api/schools/#{school.id}/classes", headers:, params: new_params)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to be_nil
  end

  it 'sets the class teacher to the specified user for school-owner users' do
    post("/api/schools/#{school.id}/classes", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_id]).to eq(teacher_id)
  end

  it 'sets the class teacher to the current user for school-teacher users' do
    stub_hydra_public_api(user_index: teacher_index)
    new_params = { school_class: params[:school_class].merge(teacher_id: 'ignored') }

    post("/api/schools/#{school.id}/classes", headers:, params: new_params)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_id]).to eq(teacher_id)
  end

  it 'responds 400 Bad Request when params are missing' do
    post("/api/schools/#{school.id}/classes", headers:)
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/classes", headers:, params: { school_class: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post "/api/schools/#{school.id}/classes"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/classes", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    post("/api/schools/#{school.id}/classes", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
