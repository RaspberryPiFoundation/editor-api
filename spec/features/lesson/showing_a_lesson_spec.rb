# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a lesson', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(teacher)
  end

  let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'public', user_id: teacher.id) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }
  let(:school) { create(:school) }

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

  # rubocop:disable RSpec/ExampleLength
  it "responds with nil attributes for the user if their user profile doesn't exist" do
    user_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id:)
    lesson.update!(user_id:)

    get("/api/lessons/#{lesson.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:user_name]).to be_nil
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 404 Not Found when no lesson exists' do
    get('/api/lessons/not-a-real-id', headers:)
    expect(response).to have_http_status(:not_found)
  end

  context "when the lesson's visibility is 'private'" do
    let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'private') }
    let(:owner) { create(:owner, school:) }

    it 'responds 200 OK when the user owns the lesson' do
      stub_user_info_api_for(owner)
      lesson.update!(user_id: owner.id)

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
    let!(:lesson) { create(:lesson, school:, name: 'Test Lesson', visibility: 'teachers', user_id: teacher.id) }
    let(:owner) { create(:owner, school:) }

    it 'responds 200 OK when the user owns the lesson' do
      stub_user_info_api_for(owner)
      lesson.update!(user_id: owner.id)

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
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the lesson's visibility is 'students'" do
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_id: teacher.id, school:) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students', user_id: teacher.id) }
    let(:teacher) { create(:teacher, school:) }

    it 'responds 200 OK when the user owns the lesson' do
      another_teacher = create(:teacher, school:)
      authenticated_in_hydra_as(another_teacher)
      lesson.update!(user_id: teacher.id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end

    # rubocop:disable RSpec/ExampleLength
    it "responds 200 OK when the user is a school-student within the lesson's class" do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)
      stub_user_info_api_for(student)
      create(:class_member, school_class:, student_id: student.id)

      get("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:ok)
    end
    # rubocop:enable RSpec/ExampleLength

    it "responds 403 Forbidden when the user is a school-student but isn't within the lesson's class" do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

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
