# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a lesson', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, name: 'Test Lesson', user_id: owner_id) }
  let(:owner_index) { user_index_by_role('school-owner') }
  let(:owner_id) { user_id_by_index(owner_index) }

  let(:params) do
    {
      lesson: {
        name: 'New Name'
      }
    }
  end

  it 'responds 200 OK' do
    put("/api/lessons/#{lesson.id}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the lesson JSON' do
    put("/api/lessons/#{lesson.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds with the user JSON' do
    put("/api/lessons/#{lesson.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:user_name]).to eq('School Owner')
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    put("/api/lessons/#{lesson.id}", headers:, params: { lesson: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/lessons/#{lesson.id}", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it "responds 403 Forbidden when the user is not the lesson's owner" do
    lesson.update!(user_id: SecureRandom.uuid)

    put("/api/lessons/#{lesson.id}", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  context 'when the lesson is associated with a school (library)' do
    let(:school) { create(:school) }
    let!(:lesson) { create(:lesson, school:, name: 'Test Lesson', visibility: 'teachers') }

    it 'responds 200 OK when the user is a school-owner' do
      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:ok)
    end

    it 'responds 200 OK when assigning the lesson to a school class' do
      school_class = create(:school_class, school:)

      new_params = { lesson: params[:lesson].merge(school_class_id: school_class.id) }
      put("/api/lessons/#{lesson.id}", headers:, params: new_params)

      expect(response).to have_http_status(:ok)
    end

    it "responds 403 Forbidden when the user a school-owner but visibility is 'private'" do
      lesson.update!(visibility: 'private')

      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is another school-teacher in the school' do
      authenticate_as_school_teacher
      lesson.update!(user_id: SecureRandom.uuid)

      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      authenticate_as_school_student

      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the lesson is associated with a school class' do
    let(:school_class) { create(:school_class) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students') }

    it 'responds 200 OK when the user is a school-owner' do
      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:ok)
    end

    it 'responds 422 Unprocessable Entity when trying to re-assign the lesson to a different class' do
      school = create(:school, id: SecureRandom.uuid)
      school_class = create(:school_class, school:, teacher_id: SecureRandom.uuid)

      new_params = { lesson: params[:lesson].merge(school_class_id: school_class.id) }
      put("/api/lessons/#{lesson.id}", headers:, params: new_params)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds 422 Unprocessable Entity when trying to re-assign the lesson to a different user' do
      new_params = { lesson: params[:lesson].merge(user_id: owner_id) }
      put("/api/lessons/#{lesson.id}", headers:, params: new_params)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
