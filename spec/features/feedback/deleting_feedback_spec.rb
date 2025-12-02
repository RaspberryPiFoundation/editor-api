# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Delete feedback requests', type: :request do
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

    context 'when deleting feedback on student work' do
      before do
        delete("/api/projects/#{student_project.identifier}/feedback/#{feedback.id}", headers:)
        student_project.reload
      end

      it 'returns no content response' do
        expect(response).to have_http_status(:no_content)
      end

      it 'removes the feedback from the school project' do
        expect(student_project.school_project.feedback.count).to eq(0)
      end
    end

    context 'when attempting to delete non-existent feedback' do
      before do
        delete("/api/projects/#{student_project.identifier}/feedback/invalid-id", headers:)
      end

      it 'returns unprocessable entity response' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error]).to match(/Couldn't find Feedback with 'id'="invalid-id"/)
      end
    end
  end

  context 'when logged in as the school owner' do
    let(:owner) { create(:owner, school:) }
    before do
      authenticated_in_hydra_as(owner)
      delete("/api/projects/#{student_project.identifier}/feedback/#{feedback.id}", headers:)
      student_project.reload
    end

    it 'returns no content response' do
      expect(response).to have_http_status(:no_content)
    end

    it 'removes the feedback from the school project' do
      expect(student_project.school_project.feedback.count).to eq(0)
    end
  end

  context 'when logged in as a teacher not in the class' do
    let(:other_teacher) { create(:teacher, school:) }
    before do
      authenticated_in_hydra_as(other_teacher)
      delete("/api/projects/#{student_project.identifier}/feedback/#{feedback.id}", headers:)
      student_project.reload
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not remove the feedback from the school project' do
      expect(student_project.school_project.feedback.count).to eq(1)
    end
  end

  context 'when logged in as a school student' do
    before do
      authenticated_in_hydra_as(student)
      delete("/api/projects/#{student_project.identifier}/feedback/#{feedback.id}", headers:)
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not remove the feedback from the school project' do
      expect(student_project.school_project.feedback.count).to eq(1)
    end
  end
end




