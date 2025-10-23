# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'List feedback requests', type: :request do
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

  context 'when logged in as the class teacher' do
    before do
      authenticated_in_hydra_as(teacher)
    end

    context 'when listing feedback for student work' do
      before do
        get("/api/projects/#{student_project.identifier}/feedback", headers:)
      end

      it 'returns ok response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a list of the feedback' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data.count).to eq(1)
      end

      it 'returns the feedback json containing feedback content' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[0][:content]).to eq(feedback.content)
      end
    end

    context 'when listing feedback for a project that is not student work' do
      before do
        get("/api/projects/#{teacher_project.identifier}/feedback", headers:)
      end

      it 'returns ok response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns an empty list' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data).to be_empty
      end
    end

    context 'when the project does not exist' do
      before do
        get('/api/projects/does-not-exist/feedback', headers:)
      end

      it 'returns not found response' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'when logged in as another teacher' do
    let(:other_teacher) { create(:teacher, school:) }

    before do
      authenticated_in_hydra_as(other_teacher)
      get("/api/projects/#{student_project.identifier}/feedback", headers:)
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when logged in as the student' do
    before do
      authenticated_in_hydra_as(student)
      get("/api/projects/#{student_project.identifier}/feedback", headers:)
    end

    it 'returns ok response' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns the feedback json containing feedback content' do
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[0][:content]).to eq(feedback.content)
    end
  end
end
