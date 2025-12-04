# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school classes', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for_users([teacher, owner_teacher].map(&:id), users: [owner_teacher, teacher])

    create(:class_student, school_class:, student_id: student.id)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, name: 'Test School Class', teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }

  let(:owner_teacher) { create(:teacher, school:, id: owner.id, name: owner.name, email: owner.email) }
  let!(:owner_school_class) { create(:school_class, name: 'Owner School Class', teacher_ids: [owner_teacher.id], school:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school classes JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School Class')
  end

  it 'only responds with the user\'s classes if the my_classes param is present' do
    get("/api/schools/#{school.id}/classes?my_classes=true", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq(owner_school_class.name)
  end

  it 'responds with the teachers JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data.first[:teachers].first[:name]).to eq('School Teacher')
  end

  it "skips teachers if the user profile doesn't exist" do
    stub_user_info_api_for_unknown_users(user_id: teacher.id)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data.first[:teachers].first).to be_nil
  end

  it 'includes submitted_count if user is a school-teacher' do
    authenticated_in_hydra_as(teacher)
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data.first).to have_key(:submitted_count)
  end

  it 'includes submitted_count if user is a school-owner' do
    authenticated_in_hydra_as(owner)
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data.first).to have_key(:submitted_count)
  end

  it 'does not include submitted_count if user is a school-student' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data.first).not_to have_key(:submitted_count)
  end

  it "does not include school classes that the school-teacher doesn't teach" do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)
    create(:school_class, school:, teacher_ids: [teacher.id])

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it "does not include school classes that the school-student isn't a member of" do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)
    create(:school_class, school:, teacher_ids: [teacher.id])

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'includes unread_feedback_count for a school-student' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    lesson = create(
      :lesson,
      school: school,
      school_class: school_class,
      visibility: 'students',
      user_id: teacher.id
    )

    remix = create(
      :project,
      school: school,
      lesson: lesson,
      parent: lesson.project,
      remixed_from_id: lesson.project.id,
      user_id: student.id
    )

    create(
      :feedback,
      school_project: remix.school_project,
      user_id: teacher.id,
      content: 'Not read',
      read_at: nil
    )

    create(
      :feedback,
      school_project: remix.school_project,
      user_id: teacher.id,
      content: 'Already read',
      read_at: Time.current
    )

    get("/api/schools/#{school.id}/classes", headers:)

    data = JSON.parse(response.body, symbolize_names: true)
    this_class = data.find { |c| c[:name] == 'Test School Class' }

    expect(this_class[:unread_feedback_count]).to eq(1)
  end

  it 'returns correct unread_feedback_count across multiple classes with different amounts of unread feedback' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    # Create a second class the student is a member of
    school_class_2 = create(:school_class, name: 'Second Class', teacher_ids: [teacher.id], school:)
    create(:class_student, school_class: school_class_2, student_id: student.id)

    # Class 1: Create 2 remixes with unread feedback
    lesson_one = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)
    remix_one = create(:project, school:, lesson: lesson_one, parent: lesson_one.project, remixed_from_id: lesson_one.project.id, user_id: student.id)
    create(:feedback, school_project: remix_one.school_project, user_id: teacher.id, content: 'Unread 1', read_at: nil)

    lesson_two = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)
    remix_two = create(:project, school:, lesson: lesson_two, parent: lesson_two.project, remixed_from_id: lesson_two.project.id, user_id: student.id)
    create(:feedback, school_project: remix_two.school_project, user_id: teacher.id, content: 'Unread 2', read_at: nil)

    # Class 2: Create 1 remix with unread feedback
    lesson_three = create(:lesson, school:, school_class: school_class_2, visibility: 'students', user_id: teacher.id)
    remix_three = create(:project, school:, lesson: lesson_three, parent: lesson_three.project, remixed_from_id: lesson_three.project.id, user_id: student.id)
    create(:feedback, school_project: remix_three.school_project, user_id: teacher.id, content: 'Unread 3', read_at: nil)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    class_1 = data.find { |c| c[:name] == 'Test School Class' }
    class_2 = data.find { |c| c[:name] == 'Second Class' }

    expect(class_1[:unread_feedback_count]).to eq(2)
    expect(class_2[:unread_feedback_count]).to eq(1)
  end

  it 'returns 0 unread_feedback_count when class has no unread feedback' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    lesson = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)
    remix = create(:project, school:, lesson:, parent: lesson.project, remixed_from_id: lesson.project.id, user_id: student.id)

    create(:feedback, school_project: remix.school_project, user_id: teacher.id, content: 'Already read', read_at: Time.current)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    this_class = data.find { |c| c[:name] == 'Test School Class' }
    expect(this_class[:unread_feedback_count]).to eq(0)
  end

  it 'returns 0 unread_feedback_count when class has no feedback' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    this_class = data.find { |c| c[:name] == 'Test School Class' }
    expect(this_class[:unread_feedback_count]).to eq(0)
  end

  it 'counts projects with unread feedback, not individual feedback items' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    lesson = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)
    remix = create(:project, school:, lesson:, parent: lesson.project, remixed_from_id: lesson.project.id, user_id: student.id)

    # Multiple unread feedback on the same project should count as 1
    create(:feedback, school_project: remix.school_project, user_id: teacher.id, content: 'Unread 1', read_at: nil)
    create(:feedback, school_project: remix.school_project, user_id: teacher.id, content: 'Unread 2', read_at: nil)
    create(:feedback, school_project: remix.school_project, user_id: teacher.id, content: 'Unread 3', read_at: nil)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    this_class = data.find { |c| c[:name] == 'Test School Class' }
    expect(this_class[:unread_feedback_count]).to eq(1)
  end

  it 'only counts unread feedback on the current students remixes' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    other_student = create(:student, school:)
    create(:class_student, school_class:, student_id: other_student.id)

    lesson = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)

    # Current student's remix with unread feedback
    my_remix = create(:project, school:, lesson:, parent: lesson.project, remixed_from_id: lesson.project.id, user_id: student.id)
    create(:feedback, school_project: my_remix.school_project, user_id: teacher.id, content: 'My unread', read_at: nil)

    # Other student's remix with unread feedback (should not count)
    other_remix = create(:project, school:, lesson:, parent: lesson.project, remixed_from_id: lesson.project.id, user_id: other_student.id)
    create(:feedback, school_project: other_remix.school_project, user_id: teacher.id, content: 'Other unread', read_at: nil)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    this_class = data.find { |c| c[:name] == 'Test School Class' }
    expect(this_class[:unread_feedback_count]).to eq(1)
  end

  it 'does not count unread feedback on lessons the student cannot access' do
    authenticated_in_hydra_as(student)
    stub_user_info_api_for(teacher)

    # Visible lesson
    visible_lesson = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)
    visible_remix = create(:project, school:, lesson: visible_lesson, parent: visible_lesson.project, remixed_from_id: visible_lesson.project.id, user_id: student.id)
    create(:feedback, school_project: visible_remix.school_project, user_id: teacher.id, content: 'Visible', read_at: nil)

    # Hidden lesson (visibility: 'teachers')
    hidden_lesson = create(:lesson, school:, school_class:, visibility: 'teachers', user_id: teacher.id)
    hidden_remix = create(:project, school:, lesson: hidden_lesson, parent: hidden_lesson.project, remixed_from_id: hidden_lesson.project.id, user_id: student.id)
    create(:feedback, school_project: hidden_remix.school_project, user_id: teacher.id, content: 'Hidden', read_at: nil)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    this_class = data.find { |c| c[:name] == 'Test School Class' }
    expect(this_class[:unread_feedback_count]).to eq(1)
  end

  it 'does not include unread_feedback_count if user is a school-teacher' do
    authenticated_in_hydra_as(teacher)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first).not_to have_key(:unread_feedback_count)
  end

  it 'does not include unread_feedback_count if user is a school-owner' do
    authenticated_in_hydra_as(owner)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first).not_to have_key(:unread_feedback_count)
  end
end
