# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Regenerating a school class join code', type: :request do
  before do
    authenticated_in_hydra_as(teacher)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let!(:school_class) { create(:school_class, name: 'Test School Class', school:, teacher_ids: [teacher.id]) }

  it 'responds 200 OK' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when the user is the school-teacher for the class' do
    authenticated_in_hydra_as(teacher)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'generates a new join code' do
    old_join_code = school_class.join_code

    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:join_code]).not_to eq(old_join_code)
    expect(data[:join_code]).to match(JoinCodeGenerator::FORMAT_REGEX)
  end

  it 'responds with the updated school class JSON including the new join code' do
    old_join_code = school_class.join_code

    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:id]).to eq(school_class.id)
    expect(data[:name]).to eq('Test School Class')
    expect(data[:join_code]).to be_present
    expect(data[:join_code]).not_to eq(old_join_code)
  end

  it 'responds with the teacher JSON' do
    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:teachers].first[:name]).to eq('School Teacher')
  end

  it 'responds 401 Unauthorized when no token is given' do
    post "/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    other_school = create(:school)
    other_class = create(:school_class, school: other_school)

    post("/api/schools/#{other_school.id}/classes/#{other_class.id}/regenerate_join_code", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    other_teacher = create(:teacher, school:)
    authenticated_in_hydra_as(other_teacher)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/regenerate_join_code", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
