# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a lesson', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api_for_teacher(teacher_id: User::TEACHER_ID)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, name: 'Test Lesson', user_id: owner_id) }
  let(:owner_id) { User::OWNER_ID }

  let(:params) do
    {
      lesson: {
        name: 'New Name'
      }
    }
  end

  it 'responds 200 OK' do
    stub_user_info_api_for_owner(owner_id: User::OWNER_ID)
    put("/api/lessons/#{lesson.id}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the lesson JSON' do
    stub_user_info_api_for_owner(owner_id: User::OWNER_ID)
    put("/api/lessons/#{lesson.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds with the user JSON' do
    stub_user_info_api_for_owner(owner_id: User::OWNER_ID)
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
      school_class = create(:school_class, school:, teacher_id: User::TEACHER_ID)

      new_params = { lesson: params[:lesson].merge(school_class_id: school_class.id) }
      put("/api/lessons/#{lesson.id}", headers:, params: new_params)

      expect(response).to have_http_status(:ok)
    end

    it "responds 403 Forbidden when the user a school-owner but visibility is 'private'" do
      lesson.update!(visibility: 'private')

      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'responds 403 Forbidden when the user is another school-teacher in the school' do
      user_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id:)
      authenticate_as_school_teacher
      lesson.update!(user_id:)

      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
    # rubocop:enable RSpec/ExampleLength

    it 'responds 403 Forbidden when the user is a school-student' do
      authenticate_as_school_student

      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the lesson is associated with a school class' do
    let(:school_class) { create(:school_class, teacher_id: User::TEACHER_ID) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students') }

    it 'responds 200 OK when the user is a school-owner' do
      put("/api/lessons/#{lesson.id}", headers:, params:)
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'responds 422 Unprocessable Entity when trying to re-assign the lesson to a different class' do
      teacher_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id: teacher_id)
      school = create(:school, id: SecureRandom.uuid)
      school_class = create(:school_class, school:, teacher_id:)

      new_params = { lesson: params[:lesson].merge(school_class_id: school_class.id) }
      put("/api/lessons/#{lesson.id}", headers:, params: new_params)

      expect(response).to have_http_status(:unprocessable_entity)
    end
    # rubocop:enable RSpec/ExampleLength

    it 'responds 422 Unprocessable Entity when trying to re-assign the lesson to a different user' do
      stub_user_info_api_for_owner(owner_id: User::OWNER_ID)
      new_params = { lesson: params[:lesson].merge(user_id: owner_id) }
      put("/api/lessons/#{lesson.id}", headers:, params: new_params)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
