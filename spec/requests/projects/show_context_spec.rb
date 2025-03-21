# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project context requests' do
  let(:headers) { {} }
  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
  let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }

  context 'when user is a teacher' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    before do
      authenticated_in_hydra_as(teacher)
      stub_profile_api_list_school_students(school:, student_attributes: [{ name: 'Joe Bloggs' }])
    end

    context 'when loading own project context' do
      let!(:project) { create(:project, :with_instructions, school:, lesson:, user_id: teacher.id, locale: nil) }
      let(:project_context_json) do
        {
          identifier: project.identifier,
          school_id: project.school_id,
          lesson_id: project.lesson_id,
          class_id: project.lesson.school_class_id
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{project.identifier}/context", headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns json' do
        get("/api/projects/#{project.identifier}/context", headers:)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'returns the project json' do
        get("/api/projects/#{project.identifier}/context", headers:)
        expect(response.body).to eq(project_context_json)
      end
    end

    context 'when loading another teacher\'s project context in a class where user is a teacher' do
      before do
        stub_user_info_api_for_users([teacher.id, another_teacher.id], users: [teacher, another_teacher])
      end

      let(:another_teacher) { create(:teacher, school:) }
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id, another_teacher.id]) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: another_teacher.id, visibility: 'teachers') }
      let(:another_teacher_project) { create(:project, :with_instructions, school:, lesson:, user_id: another_teacher.id, locale: nil) }
      let(:another_teacher_project_context_json) do
        {
          identifier: another_teacher_project.identifier,
          school_id: another_teacher_project.school_id,
          lesson_id: another_teacher_project.lesson_id,
          class_id: another_teacher_project.lesson.school_class_id
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{another_teacher_project.identifier}/context", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns the project json' do
        get("/api/projects/#{another_teacher_project.identifier}/context", headers:)
        expect(response.body).to eq(another_teacher_project_context_json)
      end
    end

    context 'when loading another user\'s project context' do
      let!(:another_project) { create(:project, user_id: SecureRandom.uuid, locale: nil) }
      let(:another_project_json) do
        {
          identifier: another_project.identifier
        }.to_json
      end

      it 'returns forbidden response' do
        get("/api/projects/#{another_project.identifier}", headers:)

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not return the project json' do
        get("/api/projects/#{another_project.identifier}", headers:)
        expect(response.body).not_to include(another_project_json)
      end
    end
  end

  context 'when user is a student' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }
    let(:student) { create(:student, school:) }
    let!(:project) { create(:project, :with_instructions, school:, lesson:, user_id: teacher.id, locale: nil) }
    let(:project_context_json) do
      {
        identifier: project.identifier,
        school_id: project.school_id,
        lesson_id: project.lesson_id,
        class_id: project.lesson.school_class_id
      }.to_json
    end

    before do
      authenticated_in_hydra_as(student)
    end

    context 'when student is in the class' do
      before do
        create(:class_student, school_class:, student_id: student.id)
      end

      context 'when loading context of a lesson project that is visible to students' do
        it 'returns success response' do
          pp project.lesson.visibility
          get("/api/projects/#{project.identifier}/context", headers:)

          expect(response).to have_http_status(:ok)
        end

        it 'returns json' do
          get("/api/projects/#{project.identifier}/context", headers:)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end

        it 'returns the project context json' do
          get("/api/projects/#{project.identifier}/context", headers:)
          expect(response.body).to eq(project_context_json)
        end
      end

      context 'when loading context of a lesson project that is not visible to students' do
        before do
          project.lesson.update(visibility: 'teachers')
        end

        it 'returns forbidden response' do
          get("/api/projects/#{project.identifier}/context", headers:)

          expect(response).to have_http_status(:forbidden)
        end

        it 'does not return the project context json' do
          get("/api/projects/#{project.identifier}/context", headers:)
          expect(response.body).not_to include(project_context_json)
        end
      end
    end

    context 'when student is not in the class' do
      it 'returns forbidden response' do
        get("/api/projects/#{project.identifier}/context", headers:)
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not return the project context json' do
        get("/api/projects/#{project.identifier}/context", headers:)
        expect(response.body).not_to include(project_context_json)
      end
    end
  end
end
