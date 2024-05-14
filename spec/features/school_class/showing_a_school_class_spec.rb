# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a school class', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let!(:school_class) { create(:school_class, name: 'Test School Class') }
  let(:school) { school_class.school }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is the class teacher' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is a student in the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))
    create(:class_member, school_class:)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school class JSON' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test School Class')
  end

  it 'responds with the teacher JSON' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to eq('School Teacher')
  end

  it "responds with nil attributes for the teacher if their user profile doesn't exist" do
    school_class.update!(teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teacher_name]).to be_nil
  end

  it 'responds 404 Not Found when no school exists' do
    get("/api/schools/not-a-real-id/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 404 Not Found when no school class exists' do
    get("/api/schools/#{school.id}/classes/not-a-real-id", headers:)
    expect(response).to have_http_status(:not_found)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes/#{school_class.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
    school_class.update!(teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not a school-student for the class' do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))

    get("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
