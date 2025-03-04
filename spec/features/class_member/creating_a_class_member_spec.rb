# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a class member', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:, name: 'School Student', username: 'school-student') }
  let(:teacher) { create(:teacher, school:) }
  let(:another_teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:) }

  let(:student_params) do
    {
      class_member: {
        user_id: student.id,
        type: 'student'
      }
    }
  end

  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(student)
  end

  context 'with valid params' do
    context 'when new class member is a student' do
      let(:student_attributes) { { id: student.id, name: student.name, username: student.username } }

      before do
        stub_profile_api_list_school_students(school:, student_attributes: [student_attributes])
      end

      it 'responds 201 Created' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
        expect(response).to have_http_status(:created)
      end

      it 'responds 201 Created when the user is a school-teacher' do
        authenticated_in_hydra_as(teacher)

        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
        expect(response).to have_http_status(:created)
      end

      it 'responds with the class member JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:class_member][:student_id]).to eq(student.id)
      end

      it 'responds with the student JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
        data = JSON.parse(response.body, symbolize_names: true)

        response_student = data[:class_member][:student]

        expect(response_student).to eq(student_attributes)
      end
    end

    context 'when new class member is a teacher' do
      let(:teacher_params) do
        {
          class_member: {
            user_id: another_teacher.id,
            type: 'teacher'
          }
        }
      end

      let(:teacher_attributes) { { id: another_teacher.id, name: another_teacher.name, email: another_teacher.email } }

      before do
        # authenticated_in_hydra_as(teacher)
        # stub_profile_api_list_school_teachers(school:, teacher_attributes: [teacher_attributes])
        stub_user_info_api_for(another_teacher)
      end

      it 'responds 201 Created' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: teacher_params)
        pp response
        expect(response).to have_http_status(:created)
      end

      it 'responds 201 Created when the user is a school-teacher' do
        authenticated_in_hydra_as(teacher)

        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: teacher_params)
        expect(response).to have_http_status(:created)
      end

      it 'responds with the class member JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: teacher_params)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:class_member][:teacher_id]).to eq(another_teacher.id)
      end

      it 'responds with the teacher JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: teacher_params)
        data = JSON.parse(response.body, symbolize_names: true)

        response_teacher = data[:class_member][:teacher]

        expect(response_teacher).to eq(teacher_attributes)
      end
    end
  end

  context 'with invalid params' do
    let(:invalid_params) { { class_member: { user_id: SecureRandom.uuid } } }

    before do
      stub_profile_api_list_school_students(school:, student_attributes: [])
    end

    it 'responds 400 Bad Request when params are missing' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds 422 Unprocessable Entity when params are invalid' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: invalid_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns the error message in the operation response' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: invalid_params)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:error]).to match(/No valid school members provided/)
    end

    it 'responds 401 Unauthorized when no token is given' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members", params: student_params)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    post("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:, params: student_params)
    expect(response).to have_http_status(:forbidden)
  end
end
