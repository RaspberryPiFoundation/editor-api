# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set read_at on feedback requests', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:class_student) { create(:class_student, school_class:, student_id: student.id) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
  let(:teacher_project) { create(:project, user_id: teacher.id, school:, lesson:) }
  let(:student_project) { create(:project, user_id: class_student.student_id, school:, parent: teacher_project) }
  let!(:feedback) { create(:feedback, school_project: student_project.school_project, user_id: teacher.id, content: 'Excellent work!') }
  let(:feedback_json) do
    {
      id: feedback.id,
      school_project_id: feedback.school_project_id,
      user_id: feedback.user_id,
      content: feedback.content,
      created_at: feedback.created_at,
      updated_at: feedback.updated_at,
      read_at: feedback.read_at
    }.to_json
  end

  context 'when logged in as the class teacher' do
    before do
      authenticated_in_hydra_as(teacher)
      put("/api/projects/#{student_project.identifier}/feedback/#{feedback.id}/read", headers: headers)
      feedback.reload
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not set the read_at on feedback' do
      expect(feedback.read_at).to be_nil
    end
  end

  context 'when logged in as the student' do
    before do
      authenticated_in_hydra_as(student)
    end

    context 'when feedback exists' do
      before do
        put("/api/projects/#{student_project.identifier}/feedback/#{feedback.id}/read", headers: headers)
        feedback.reload
      end

      it 'returns ok response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the feedback json' do
        expect(response.body).to eq(feedback_json)
      end

      it 'does set the read_at on feedback' do
        expect(feedback.read_at).to be_present
      end

      it 'sets read_at to be a time' do
        expect(feedback.read_at).to be_a(ActiveSupport::TimeWithZone)
      end

      it 'sets read_at to a recent time' do
        expect(feedback.read_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'when feedback does not exist' do
      before do
        put("/api/projects/#{student_project.identifier}/feedback/does-not-exist/read", headers: headers)
        feedback.reload
      end

      it 'returns not found response' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
