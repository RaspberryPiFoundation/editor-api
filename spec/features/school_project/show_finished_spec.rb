# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School project finished requests' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:student) { create(:student, school:) }
  let(:lesson) { build(:lesson, school:, user_id: teacher.id, visibility: 'students') }
  let(:teacher_project) { create(:project, school_id: school.id, lesson_id: lesson.id, user_id: teacher.id, locale: nil) }
  let(:student_project) { create(:project, school_id: school.id, lesson_id: nil, user_id: student.id, remixed_from_id: teacher_project.id, locale: nil, finished: true) }
  let(:school_project_json) do
    {
      id: student_project.school_project.id,
      school_id: student_project.school_project.school_id,
      project_id: student_project.school_project.project_id,
      finished: student_project.school_project.finished,
      identifier: student_project.identifier
    }.to_json
  end

  context 'when the user is a student' do
    before do
      authenticated_in_hydra_as(student)
    end

    context 'when user owns project' do
      before do
        get("/api/projects/#{student_project.identifier}/finished", headers:)
      end

      it 'returns success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns response containing correct school project data' do
        expect(response.body).to eq(school_project_json)
      end
    end

    context 'when user does not own project' do
      before do
        get("/api/projects/#{teacher_project.identifier}/finished", headers:)
      end

      it 'returns forbidden response' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when project does not exist' do
      before do
        get('/api/projects/does-not-exist/finished', headers:)
      end

      it 'returns not found response' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
