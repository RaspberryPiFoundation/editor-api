# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School project complete requests', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:class_student) { create(:class_student, school_class:, student_id: student.id) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
  let(:teacher_project) { create(:project, user_id: teacher.id, school:, lesson:) }
  let!(:student_project) { create(:project, school_id: school.id, lesson_id: nil, user_id: student.id, remixed_from_id: teacher_project.id, locale: nil, finished: false) }
  let(:school_project_json) do
    {
      id: student_project.school_project.id,
      school_id: student_project.school_project.school_id,
      project_id: student_project.school_project.project_id,
      status: student_project.school_project.status,
      identifier: student_project.identifier
    }.to_json
  end

  context 'when logged in as student' do
    before do
      authenticated_in_hydra_as(student)
      post("/api/projects/#{student_project.identifier}/complete", headers:)
    end

    it 'completes forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not change the status' do
      expect(student_project.school_project).to be_unsubmitted
    end
  end

  context 'when logged in as teacher' do
    before do
      authenticated_in_hydra_as(teacher)
    end

    context('when transition is valid') do
      before do
        student_project.school_project.transition_status_to!(:submitted, student.id)
        post("/api/projects/#{student_project.identifier}/complete", headers:)
      end

      it 'completes success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'completes the school project json' do
        expect(response.body).to eq(school_project_json)
      end

      it 'sets the status to complete' do
        expect(student_project.school_project).to be_complete
      end
    end

    context 'when attempting an invalid status transition' do
      before do
        student_project.school_project.transition_status_to!(:complete, student.id)
        post("/api/projects/#{student_project.identifier}/complete", headers:)
      end

      it 'completes unauthorized response' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'completes error message' do
        expect(JSON.parse(response.body)['error']).to eq("Cannot transition from 'complete' to 'complete'")
      end
    end
  end

  context 'when user does not own the project and is not the class teacher' do
    let(:another_teacher) { create(:teacher, school:) }

    before do
      authenticated_in_hydra_as(another_teacher)
      post("/api/projects/#{student_project.identifier}/complete", headers:)
    end

    it 'completes forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not change the status' do
      expect(student_project.school_project).to be_unsubmitted
    end
  end

  context 'when project does not exist' do
    before do
      authenticated_in_hydra_as(student)
      post('/api/projects/does-not-exist/complete', headers:)
    end

    it 'completes not found response' do
      expect(response).to have_http_status(:not_found)
    end
  end
end
