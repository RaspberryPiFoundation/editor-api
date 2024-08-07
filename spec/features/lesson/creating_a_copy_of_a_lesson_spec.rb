# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a copy of a lesson', type: :request do
  before do
    authenticated_in_hydra_as(owner)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'public', user_id: teacher.id) }
  let(:params) { {} }
  let(:teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:, name: 'School Owner') }
  let(:school) { create(:school) }

  it 'responds 201 Created' do
    post("/api/lessons/#{lesson.id}/copy", headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the lesson JSON' do
    post("/api/lessons/#{lesson.id}/copy", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test Lesson')
  end

  it 'responds with the user JSON which is set from the current user' do
    post("/api/lessons/#{lesson.id}/copy", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:user_name]).to eq('School Owner')
  end

  # See spec/concepts/lesson/create_copy_spec.rb for more examples.
  it 'only copies a subset of fields from the lesson' do
    post("/api/lessons/#{lesson.id}/copy", headers:, params:)

    data = JSON.parse(response.body, symbolize_names: true)
    values = data.slice(:copied_from_id, :name, :visibility).values

    expect(values).to eq [lesson.id, 'Test Lesson', 'teachers']
  end

  it 'can override fields from the request params' do
    new_params = { lesson: { name: 'New Name', visibility: 'public' } }
    post("/api/lessons/#{lesson.id}/copy", headers:, params: new_params)

    data = JSON.parse(response.body, symbolize_names: true)
    values = data.slice(:name, :visibility).values

    expect(values).to eq ['New Name', 'public']
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/lessons/#{lesson.id}/copy", headers:, params: { lesson: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/lessons/#{lesson.id}/copy", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  context "when the lesson's visibility is 'private'" do
    let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'private') }
    let(:owner) { create(:owner, school:) }

    it 'responds 201 Created when the user owns the lesson' do
      lesson.update!(user_id: owner.id)

      post("/api/lessons/#{lesson.id}/copy", headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 403 Forbidden when the user does not own the lesson' do
      post("/api/lessons/#{lesson.id}/copy", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the lesson's visibility is 'teachers'" do
    let(:school) { create(:school) }
    let!(:lesson) { create(:lesson, school:, name: 'Test Lesson', visibility: 'teachers', user_id: teacher.id) }
    let(:owner) { create(:owner, school:) }

    let(:params) do
      {
        lesson: {
          user_id: owner.id
        }
      }
    end

    it 'responds 201 Created when the user owns the lesson' do
      lesson.update!(user_id: owner.id)

      post("/api/lessons/#{lesson.id}/copy", headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is a school-owner or school-teacher within the school' do
      post("/api/lessons/#{lesson.id}/copy", headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      lesson.update!(school_id: school.id)

      post("/api/lessons/#{lesson.id}/copy", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      post("/api/lessons/#{lesson.id}/copy", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
