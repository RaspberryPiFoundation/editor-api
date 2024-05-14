# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a lesson', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'public') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  it 'responds 200 OK' do
    get("/api/lessons/#{lesson.id}", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when no token is given' do
    get "/api/lessons/#{lesson.id}"
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the lesson JSON' do
    get("/api/lessons/#{lesson.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test Lesson')
  end

  it 'responds with the user JSON' do
    get("/api/lessons/#{lesson.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:user_name]).to eq('School Teacher')
  end

  it "responds with nil attributes for the user if their user profile doesn't exist" do
    lesson.update!(user_id: SecureRandom.uuid)

    get("/api/lessons/#{lesson.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:user_name]).to be_nil
  end

  it 'responds 404 Not Found when no lesson exists' do
    get('/api/lessons/not-a-real-id', headers:)
    expect(response).to have_http_status(:not_found)
  end

  context "when the lesson's visibility is 'private'" do
    let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'private') }
    let(:owner_index) { user_index_by_role('school-owner') }
    let(:owner_id) { user_id_by_index(owner_index) }

    it 'responds 200 OK when the user owns the lesson' do
      lesson.update!(user_id: owner_id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'responds 403 Forbidden when the user does not own the lesson' do
      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the lesson's visibility is 'teachers'" do
    let(:school) { create(:school) }
    let!(:lesson) { create(:lesson, school:, name: 'Test Lesson', visibility: 'teachers') }
    let(:owner_index) { user_index_by_role('school-owner') }
    let(:owner_id) { user_id_by_index(owner_index) }

    it 'responds 200 OK when the user owns the lesson' do
      lesson.update!(user_id: owner_id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'responds 200 OK when the user is a school-owner or school-teacher within the school' do
      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      lesson.update!(school_id: school.id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      stub_hydra_public_api(user_index: user_index_by_role('school-student'))

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the lesson's visibility is 'students'" do
    let(:school_class) { create(:school_class) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students') }
    let(:teacher_index) { user_index_by_role('school-teacher') }
    let(:teacher_id) { user_id_by_index(teacher_index) }

    it 'responds 200 OK when the user owns the lesson' do
      stub_hydra_public_api(user_index: teacher_index)
      lesson.update!(user_id: teacher_id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end

    it "responds 200 OK when the user is a school-student within the lesson's class" do
      stub_hydra_public_api(user_index: user_index_by_role('school-student'))
      create(:class_member, school_class:)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end

    it "responds 403 Forbidden when the user is a school-student but isn't within the lesson's class" do
      stub_hydra_public_api(user_index: user_index_by_role('school-student'))

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      lesson.update!(school_id: school.id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
