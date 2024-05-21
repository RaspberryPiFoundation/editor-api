# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing lessons', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api_for_teacher(teacher_id: User::TEACHER_ID, school_id: School::ID)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'public', user_id: User::TEACHER_ID) }

  it 'responds 200 OK' do
    get('/api/lessons', headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 200 OK when no token is given' do
    get '/api/lessons'
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the lessons JSON' do
    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test Lesson')
  end

  it 'responds with the user JSON' do
    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:user_name]).to eq('School Teacher')
  end

  # rubocop:disable RSpec/ExampleLength
  it "responds with nil attributes for the user if their user profile doesn't exist" do
    user_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id:)
    lesson.update!(user_id:)

    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:user_name]).to be_nil
  end
  # rubocop:enable RSpec/ExampleLength

  it 'does not include archived lessons' do
    lesson.archive!

    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(0)
  end

  it 'includes archived lessons if ?include_archived=true is set' do
    lesson.archive!

    get('/api/lessons?include_archived=true', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  context "when the lesson's visibility is 'private'" do
    let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'private') }
    let(:owner_id) { User::OWNER_ID }

    it 'includes the lesson when the user owns the lesson' do
      stub_user_info_api_for_owner(owner_id: User::OWNER_ID, school_id: School::ID)
      lesson.update!(user_id: owner_id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end

    it 'does not include the lesson whent he user does not own the lesson' do
      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end
  end

  context "when the lesson's visibility is 'teachers'" do
    let(:school) { create(:school, id: School::ID) }
    let!(:lesson) { create(:lesson, school:, name: 'Test Lesson', visibility: 'teachers', user_id: User::TEACHER_ID) }
    let(:owner_id) { User::OWNER_ID }

    it 'includes the lesson when the user owns the lesson' do
      stub_user_info_api_for_owner(owner_id: User::OWNER_ID, school_id: School::ID)
      lesson.update!(user_id: owner_id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end

    it 'includes the lesson when the user is a school-owner or school-teacher within the school' do
      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end

    it 'does not include the lesson when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      lesson.update!(school_id: school.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end

    it 'does not include the lesson when the user is a school-student' do
      authenticate_as_school_student

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end
  end

  context "when the lesson's visibility is 'students'" do
    let(:school_class) { create(:school_class, teacher_id:, school: build(:school, id: School::ID)) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students', user_id: User::TEACHER_ID) }
    let(:teacher_id) { User::TEACHER_ID }

    it 'includes the lesson when the user owns the lesson' do
      authenticate_as_school_teacher
      lesson.update!(user_id: teacher_id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end

    # rubocop:disable RSpec/ExampleLength
    it "includes the lesson when the user is a school-student within the lesson's class" do
      stub_user_info_api_for_student(student_id: User::STUDENT_ID, school_id: School::ID)
      authenticate_as_school_student(student_id: User::STUDENT_ID)
      create(:class_member, school_class:, student_id: User::STUDENT_ID)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end
    # rubocop:enable RSpec/ExampleLength

    it "does not include the lesson when the user is not a school-student within the lesson's class" do
      authenticate_as_school_student

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end

    it 'does not include the lesson when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      lesson.update!(school_id: school.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end
  end
end
