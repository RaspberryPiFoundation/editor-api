# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing lessons', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(teacher)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'public', user_id: teacher.id) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, teacher_id: teacher.id, school:) }
  let(:another_school_class) { create(:school_class, teacher_id: teacher.id, school:) }

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

  it 'responds with the project JSON' do
    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    expected_project = JSON.parse(lesson.project.to_json(only: %i[identifier project_type]), symbolize_names: true)

    expect(data.first[:project]).to eq(expected_project)
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

  it 'does not include lessons with no class if school_class_id provided' do
    get("/api/lessons?school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(0)
  end

  it 'does not include lessons from another class if school_class_id provided' do
    lesson.update!(school_class_id: another_school_class.id)
    get("/api/lessons?school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(0)
  end

  it 'includes lessons from the class if school_class_id provided' do
    lesson.update!(school_class_id: school_class.id)

    get("/api/lessons?school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'defaults to not including archived lessons from the class if school_class_id provided' do
    lesson.archive!
    lesson.update!(school_class_id: school_class.id)
    get("/api/lessons?school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(0)
  end

  it 'includes archived lessons from class if include_archived=true and school_class_id provided' do
    lesson.archive!
    lesson.update!(school_class_id: school_class.id)
    get("/api/lessons?include_archived=true&school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  context "when the lesson's visibility is 'private'" do
    let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'private') }
    let(:owner) { create(:owner, school:) }

    it 'includes the lesson when the user owns the lesson' do
      lesson.update!(user_id: owner.id)

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
    let(:school) { create(:school) }
    let!(:lesson) { create(:lesson, school:, name: 'Test Lesson', visibility: 'teachers', user_id: teacher.id) }
    let(:owner) { create(:owner, school:) }

    it 'includes the lesson when the user owns the lesson' do
      lesson.update!(user_id: owner.id)

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
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end
  end

  context "when the lesson's visibility is 'students'" do
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_id: teacher.id, school:) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students', user_id: teacher.id) }
    let(:teacher) { create(:teacher, school:) }

    # rubocop:disable RSpec/ExampleLength
    it 'includes the lesson when the user owns the lesson' do
      another_teacher = create(:teacher, school:)
      authenticated_in_hydra_as(another_teacher)
      lesson.update!(user_id: teacher.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end
    # rubocop:enable RSpec/ExampleLength

    # rubocop:disable RSpec/ExampleLength
    it "includes the lesson when the user is a school-student within the lesson's class" do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)
      create(:class_member, school_class:, student_id: student.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end
    # rubocop:enable RSpec/ExampleLength

    it "does not include the lesson when the user is not a school-student within the lesson's class" do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

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
