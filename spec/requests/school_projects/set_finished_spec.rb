# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School project finished requests' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:student) { create(:student, school:) }
  let(:lesson) { build(:lesson, school:, user_id: teacher.id, visibility: 'students') }
  let(:teacher_project) { create(:project, school_id: school.id, lesson_id: lesson.id, user_id: teacher.id, locale: nil) }

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

    it 'sets the completed flag to false' do
      expect(student_project.school_project.finished).to be_falsey
    end
  end
end
