# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing lessons', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(teacher)
    create(:class_student, school_class:, student_id: student.id)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, name: 'Test Lesson', visibility: 'public', user_id: teacher.id) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }
  let(:student) { create(:student, school:) }
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:another_school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }

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

  it "responds with nil attributes for the user if their user profile doesn't exist" do
    user_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id:)
    lesson.update!(user_id:)

    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:user_name]).to be_nil
  end

  it 'does not include lessons that were previously archived' do
    lesson.update!(archived_at: Time.now.utc)

    get('/api/lessons', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(0)
  end

  it 'does not include previously archived lessons when filtering by school_class_id' do
    lesson.update!(school_class_id: school_class.id)
    lesson.update!(archived_at: Time.now.utc)

    get("/api/lessons?school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(0)
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

  it 'includes the submitted_count for each lesson' do
    lesson.update!(school_class_id: school_class.id)
    remix = create(:project, school:, remixed_from_id: lesson.project.id, user_id: student.id)
    remix.school_project.transition_status_to!(:submitted, student.id)

    get("/api/lessons?school_class_id=#{school_class.id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:submitted_count]).to eq(1)
  end

  context 'when filtering by project_identifier' do
    let!(:other_lesson) { create(:lesson, name: 'Another Lesson', visibility: 'public', user_id: teacher.id) }

    it 'returns only lessons with the matching project identifier' do
      # Ensure other_lesson exists with a different project
      expect(other_lesson.project.identifier).not_to eq(lesson.project.identifier)

      get("/api/lessons?project_identifier=#{lesson.project.identifier}", headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
      expect(data.first[:name]).to eq('Test Lesson')
      expect(data.first[:project][:identifier]).to eq(lesson.project.identifier)
    end

    it 'returns empty array when no lesson matches the project identifier' do
      get('/api/lessons?project_identifier=non-existent-identifier', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end

    it 'works without authentication' do
      get("/api/lessons?project_identifier=#{lesson.project.identifier}")
      data = JSON.parse(response.body, symbolize_names: true)

      expect(response).to have_http_status(:ok)
      expect(data.size).to eq(1)
      expect(data.first[:name]).to eq('Test Lesson')
    end

    it 'can be combined with school_class_id filter' do
      lesson.update!(school_class_id: school_class.id)
      other_lesson.update!(school_class_id: school_class.id)

      get("/api/lessons?school_class_id=#{school_class.id}&project_identifier=#{lesson.project.identifier}", headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
      expect(data.first[:name]).to eq('Test Lesson')
    end
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
      authenticated_in_hydra_as(student)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(0)
    end
  end

  context "when the lesson's visibility is 'students'" do
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let!(:lesson) { create(:lesson, school_class:, name: 'Test Lesson', visibility: 'students', user_id: teacher.id) }
    let(:teacher) { create(:teacher, school:) }

    let(:student_project) do
      create(
        :project,
        school:,
        lesson:,
        parent: lesson.project,
        remixed_from_id: lesson.project.id,
        user_id: student.id
      )
    end

    let(:school_project) { student_project.school_project }

    it 'includes the lesson when the user owns the lesson' do
      another_teacher = create(:teacher, school:)
      authenticated_in_hydra_as(another_teacher)
      lesson.update!(user_id: teacher.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end

    it "includes the lesson when the user is a school-student within the lesson's class" do
      authenticated_in_hydra_as(student)
      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
    end

    it 'does not include the submitted_count when the user is a school-student within the lesson\'s class' do
      authenticated_in_hydra_as(student)
      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data.first).not_to have_key(:submitted_count)
    end

    it "includes the remix identifier when the user has remixed the lesson's project" do
      authenticated_in_hydra_as(student)
      student_project = create(:project, school:, lesson:, parent: lesson.project, remixed_from_id: lesson.project.id, user_id: student.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data.first[:remix_identifier]).to eq(student_project.identifier)
    end

    it "does not include the lesson when the user is not a school-student within the lesson's class" do
      another_student = create(:student, school:)
      authenticated_in_hydra_as(another_student)

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

    it 'includes has_unread_feedback as true when there is unread feedback' do
      authenticated_in_hydra_as(student)
      create(
        :feedback,
        school_project: school_project,
        user_id: teacher.id,
        content: 'Unread',
        read_at: nil
      )

      create(
        :feedback,
        school_project: school_project,
        user_id: teacher.id,
        content: 'Read',
        read_at: Time.current
      )

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.first[:has_unread_feedback]).to be(true)
    end

    it 'includes has_unread_feedback as false when there is no unread feedback' do
      authenticated_in_hydra_as(student)
      create(
        :feedback,
        school_project: school_project,
        user_id: teacher.id,
        content: 'Read',
        read_at: Time.current
      )

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.first[:has_unread_feedback]).to be(false)
    end

    it 'includes status when the user is a student' do
      authenticated_in_hydra_as(student)
      school_project.transition_status_to!(:submitted, teacher.id)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.size).to eq(1)
      expect(data.first[:status]).to eq('submitted')
    end

    it 'includes the default status when no transitions have happened' do
      authenticated_in_hydra_as(student)
      create(
        :project,
        school:,
        lesson:,
        parent: lesson.project,
        remixed_from_id: lesson.project.id,
        user_id: student.id
      )

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.first[:status]).to eq('unsubmitted')
    end

    it 'does not include the status when the user is a teacher' do
      authenticated_in_hydra_as(teacher)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.first).not_to have_key(:status)
    end

    it 'does not include has_unread_feedback when the user is a teacher' do
      authenticated_in_hydra_as(teacher)

      get('/api/lessons', headers:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data.first).not_to have_key(:has_unread_feedback)
    end
  end
end
