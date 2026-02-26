# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create feedback requests', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:class_student) { create(:class_student, school_class:, student_id: student.id) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
  let(:teacher_project) { create(:project, user_id: teacher.id, school:, lesson:) }
  let(:student_project) { create(:project, user_id: class_student.student_id, school:, lesson:, parent: teacher_project) }

  context 'when logged in as the class teacher' do
    before do
      authenticated_in_hydra_as(teacher)
    end

    context 'when leaving feedback on student work' do
      before do
        post("/api/projects/#{student_project.identifier}/feedback", headers:, params: { feedback: { content: 'Nice one!' } })
        student_project.reload
      end

      it 'returns created response' do
        expect(response).to have_http_status(:created)
      end

      it 'returns the feedback json containing feedback content' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:content]).to eq('Nice one!')
      end

      it 'returns the feedback json containing school project id' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:school_project_id]).to eq(student_project.school_project.id)
      end

      it 'returns the feedback json containing user id' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:user_id]).to eq(teacher.id)
      end

      it 'adds the feedback to the school project' do
        expect(student_project.school_project.feedback.count).to eq(1)
      end
    end

    context 'when leaving feedback on a project that is not student work' do
      before do
        post("/api/projects/#{teacher_project.identifier}/feedback", headers:, params: { feedback: { content: 'Nice one!' } })
        teacher_project.reload
      end

      it 'returns forbidden response' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not add the feedback to the school project' do
        expect(teacher_project.school_project.feedback.count).to eq(0)
      end
    end

    context 'when leaving empty feedback' do
      before do
        post("/api/projects/#{student_project.identifier}/feedback", headers:, params: { feedback: { content: '' } })
        student_project.reload
      end

      it 'returns unprocessable entity response' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not add the feedback to the school project' do
        expect(student_project.school_project.feedback.count).to eq(0)
      end
    end

    context 'when the project does not exist' do
      before do
        post('/api/projects/does-not-exist/feedback', headers:, params: { feedback: { content: 'Nice one!' } })
      end

      it 'returns forbidden response' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'when logged in as another teacher' do
    let(:other_teacher) { create(:teacher, school:) }

    before do
      authenticated_in_hydra_as(other_teacher)
      post("/api/projects/#{student_project.identifier}/feedback", headers:, params: { feedback: { content: 'Nice one!' } })
      student_project.reload
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not add the feedback to the school project' do
      expect(student_project.school_project.feedback.count).to eq(0)
    end
  end

  context 'when logged in as the student' do
    before do
      authenticated_in_hydra_as(student)
      post("/api/projects/#{student_project.identifier}/feedback", headers:, params: { feedback: { content: 'Nice one!' } })
      student_project.reload
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not add the feedback to the school project' do
      expect(student_project.school_project.feedback.count).to eq(0)
    end
  end
end
