# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School project finished requests' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:student) { create(:student, school:) }
  let(:lesson) { build(:lesson, school:, user_id: teacher.id, visibility: 'students') }
  let(:teacher_project) { create(:project, school_id: school.id, lesson_id: lesson.id, user_id: teacher.id, locale: nil) }
  let(:school_project_json) do
    {
      id: student_project.school_project.id,
      school_id: student_project.school_project.school_id,
      project_id: student_project.school_project.project_id,
      finished: student_project.school_project.finished,
      identifier: student_project.identifier
    }.to_json
  end

  before do
    authenticated_in_hydra_as(student)
    stub_profile_api_list_school_students(school:, student_attributes: [{ name: 'Joe Bloggs' }])
  end

  context 'when the finished flag is initially false' do
    let!(:student_project) { create(:project, school_id: school.id, lesson_id: nil, user_id: student.id, remixed_from_id: teacher_project.id, locale: nil, finished: false) }

    before do
      put("/api/projects/#{student_project.identifier}/finished", headers:, params: { finished: true })
      student_project.reload
    end

    it 'returns success response' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns the school project json' do
      expect(response.body).to eq(school_project_json)
    end

    it 'sets the completed flag to true' do
      expect(student_project.school_project.finished).to be_truthy
    end
  end

  context 'when the finished flag is initially true' do
    let!(:student_project) { create(:project, school_id: school.id, lesson_id: nil, user_id: student.id, remixed_from_id: teacher_project.id, locale: nil, finished: true) }

    before do
      put("/api/projects/#{student_project.identifier}/finished", headers:, params: { finished: false })
      student_project.reload
    end

    it 'returns success response' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns the school project json' do
      expect(response.body).to eq(school_project_json)
    end

    it 'sets the completed flag to false' do
      expect(student_project.school_project.finished).to be_falsey
    end
  end

  context 'when the user does not own the project' do
    before do
      put("/api/projects/#{teacher_project.identifier}/finished", headers:, params: { finished: true })
      teacher_project.reload
    end

    it 'returns forbidden response' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not change the finished flag' do
      expect(teacher_project.school_project.finished).to be_falsey
    end
  end

  context 'when project does not exist' do
    before do
      put('/api/projects/does-not-exist/finished', headers:, params: { finished: false })
    end

    it 'returns not found response' do
      expect(response).to have_http_status(:not_found)
    end
  end
end
