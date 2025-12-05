# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school classes', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }
  let(:owner_teacher) { create(:teacher, school:, id: owner.id, name: owner.name, email: owner.email) }

  let!(:school_class) { create(:school_class, name: 'Test School Class', teacher_ids: [teacher.id], school:) }
  let!(:owner_school_class) { create(:school_class, name: 'Owner School Class', teacher_ids: [owner_teacher.id], school:) }

  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for_users([teacher, owner_teacher].map(&:id), users: [owner_teacher, teacher])
    create(:class_student, school_class:, student_id: student.id)
  end

  # Helper to make API call and parse response
  def get_classes(path = "/api/schools/#{school.id}/classes")
    get(path, headers:)
    JSON.parse(response.body, symbolize_names: true)
  end

  def find_school_class_by_name(data, name)
    data.find { |school_class| school_class[:name] == name }
  end

  # Helper to create a lesson with a student remix and optional feedback
  def create_remix_with_feedback(school_class:, student:, feedback_attrs: [])
    lesson = create(:lesson, school:, school_class:, visibility: 'students', user_id: teacher.id)
    remix = create(:project, school:, parent: lesson.project, remixed_from_id: lesson.project.id, user_id: student.id)

    feedback_attrs.each do |attrs|
      create(:feedback, school_project: remix.school_project, user_id: teacher.id, **attrs)
    end

    { lesson:, remix: }
  end

  describe 'basic responses' do
    it 'responds 200 OK' do
      get_classes
      expect(response).to have_http_status(:ok)
    end

    it 'responds with the school classes JSON' do
      data = get_classes
      expect(data.first[:name]).to eq('Test School Class')
    end

    it 'responds with the teachers JSON' do
      data = get_classes
      expect(data.first[:teachers].first[:name]).to eq('School Teacher')
    end

    it "skips teachers if the user profile doesn't exist" do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      data = get_classes
      expect(data.first[:teachers].first).to be_nil
    end

    it 'responds 401 Unauthorized when no token is given' do
      get "/api/schools/#{school.id}/classes"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      other_school = create(:school, id: SecureRandom.uuid)
      school_class.update!(school_id: other_school.id)

      get("/api/schools/#{other_school.id}/classes/#{school_class.id}/members", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'my_classes filter' do
    it "only responds with the user's classes if the my_classes param is present" do
      data = get_classes("/api/schools/#{school.id}/classes?my_classes=true")
      expect(data.first[:name]).to eq(owner_school_class.name)
    end
  end

  describe 'class visibility' do
    it "does not include school classes that the school-teacher doesn't teach" do
      other_teacher = create(:teacher, school:)
      authenticated_in_hydra_as(other_teacher)
      create(:school_class, school:, teacher_ids: [other_teacher.id])

      data = get_classes
      expect(data.size).to eq(1)
    end

    it "does not include school classes that the school-student isn't a member of" do
      authenticated_in_hydra_as(student)
      stub_user_info_api_for(teacher)
      create(:school_class, school:, teacher_ids: [teacher.id])

      data = get_classes
      expect(data.size).to eq(1)
    end
  end

  describe 'submitted_count' do
    it 'includes submitted_count if user is a school-teacher' do
      authenticated_in_hydra_as(teacher)
      data = get_classes
      expect(data.first).to have_key(:submitted_count)
    end

    it 'includes submitted_count if user is a school-owner' do
      data = get_classes
      expect(data.first).to have_key(:submitted_count)
    end

    it 'does not include submitted_count if user is a school-student' do
      authenticated_in_hydra_as(student)
      stub_user_info_api_for(teacher)
      data = get_classes
      expect(data.first).not_to have_key(:submitted_count)
    end
  end

  describe 'unread_feedback_count' do
    context 'when user is a school-student' do
      before do
        authenticated_in_hydra_as(student)
        stub_user_info_api_for(teacher)
      end

      it 'includes unread_feedback_count' do
        create_remix_with_feedback(
          school_class:,
          student:,
          feedback_attrs: [
            { content: 'Not read', read_at: nil },
            { content: 'Already read', read_at: Time.current }
          ]
        )

        data = get_classes
        this_class = find_school_class_by_name(data, 'Test School Class')
        expect(this_class[:unread_feedback_count]).to eq(1)
      end

      it 'returns correct counts across multiple classes' do
        school_class_2 = create(:school_class, name: 'Second Class', teacher_ids: [teacher.id], school:)
        create(:class_student, school_class: school_class_2, student_id: student.id)

        # Class 1: 2 remixes with unread feedback
        create_remix_with_feedback(school_class:, student:, feedback_attrs: [{ content: 'Unread', read_at: nil }])
        create_remix_with_feedback(school_class:, student:, feedback_attrs: [{ content: 'Unread', read_at: nil }])

        # Class 2: 1 remix with unread feedback
        create_remix_with_feedback(school_class: school_class_2, student:, feedback_attrs: [{ content: 'Unread', read_at: nil }])

        data = get_classes
        expect(find_school_class_by_name(data, 'Test School Class')[:unread_feedback_count]).to eq(2)
        expect(find_school_class_by_name(data, 'Second Class')[:unread_feedback_count]).to eq(1)
      end

      it 'returns 0 when all feedback is read' do
        create_remix_with_feedback(school_class:, student:, feedback_attrs: [{ content: 'Read', read_at: Time.current }])

        data = get_classes
        this_class = find_school_class_by_name(data, 'Test School Class')
        expect(this_class[:unread_feedback_count]).to eq(0)
      end

      it 'returns 0 when class has no feedback' do
        data = get_classes
        this_class = find_school_class_by_name(data, 'Test School Class')
        expect(this_class[:unread_feedback_count]).to eq(0)
      end

      it 'counts projects not individual feedback items' do
        create_remix_with_feedback(
          school_class:,
          student:,
          feedback_attrs: [
            { content: 'Unread 1', read_at: nil },
            { content: 'Unread 2', read_at: nil },
            { content: 'Unread 3', read_at: nil }
          ]
        )

        data = get_classes
        this_class = find_school_class_by_name(data, 'Test School Class')
        expect(this_class[:unread_feedback_count]).to eq(1)
      end

      it "only counts the current student's remixes" do
        other_student = create(:student, school:)
        create(:class_student, school_class:, student_id: other_student.id)

        create_remix_with_feedback(school_class:, student:, feedback_attrs: [{ content: 'Mine', read_at: nil }])
        create_remix_with_feedback(school_class:, student: other_student, feedback_attrs: [{ content: 'Theirs', read_at: nil }])

        data = get_classes
        this_class = find_school_class_by_name(data, 'Test School Class')
        expect(this_class[:unread_feedback_count]).to eq(1)
      end

      it 'does not count feedback on inaccessible lessons' do
        # Visible lesson
        create_remix_with_feedback(school_class:, student:, feedback_attrs: [{ content: 'Visible', read_at: nil }])

        # Hidden lesson
        hidden_lesson = create(:lesson, school:, school_class:, visibility: 'teachers', user_id: teacher.id)
        hidden_remix = create(:project, school:, parent: hidden_lesson.project, remixed_from_id: hidden_lesson.project.id, user_id: student.id)
        create(:feedback, school_project: hidden_remix.school_project, user_id: teacher.id, content: 'Hidden', read_at: nil)

        data = get_classes
        this_class = find_school_class_by_name(data, 'Test School Class')
        expect(this_class[:unread_feedback_count]).to eq(1)
      end
    end

    context 'when user is a school-teacher' do
      it 'does not include unread_feedback_count' do
        authenticated_in_hydra_as(teacher)
        data = get_classes
        expect(data.first).not_to have_key(:unread_feedback_count)
      end
    end

    context 'when user is a school-owner' do
      it 'does not include unread_feedback_count' do
        data = get_classes
        expect(data.first).not_to have_key(:unread_feedback_count)
      end
    end
  end
end
