# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School project status requests', type: :request do
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
      get("/api/projects/#{student_project.identifier}/status", headers:)
    end

    it 'returns success response' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns the school project json' do
      expect(response.body).to eq(school_project_json)
    end
  end

  context 'when logged in as teacher' do
    before do
      authenticated_in_hydra_as(teacher)
    end

    context 'when transition is valid' do
      before do
        get("/api/projects/#{student_project.identifier}/status", headers:)
      end

      it 'returns success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the school project json' do
        expect(response.body).to eq(school_project_json)
      end
    end
  end

  context 'when user does not own the project and is not the class teacher' do
    let(:another_teacher) { create(:teacher, school:) }

    before do
      authenticated_in_hydra_as(another_teacher)
      get("/api/projects/#{student_project.identifier}/status", headers:)
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not return the school project json' do
      expect(response.body).not_to eq(school_project_json)
    end
  end

  context 'when project does not exist' do
    before do
      authenticated_in_hydra_as(student)
      get('/api/projects/does-not-exist/status', headers:)
    end

    it 'returns not found response' do
      expect(response).to have_http_status(:not_found)
    end
  end
end
