# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a school class', type: :request do
  before do
    authenticate_as_school_teacher(teacher)
    stub_user_info_api_for(teacher)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let!(:school_class) { create(:school_class, name: 'Test School Class', school:, teacher_id: teacher.id) }

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
    authenticate_as_school_teacher(teacher)

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
    teacher = create(:teacher, school:)
    authenticate_as_school_teacher(teacher)

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    put("/api/schools/#{school.id}/classes/#{school_class.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
