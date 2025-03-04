# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a class member', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:) }

  let(:params) do
    {
      student_ids: students.map(&:id)
    }
  end

  context 'with valid params' do
    let(:student_attributes) do
      students.map do |student|
        { id: student.id, name: student.name, username: student.username }
      end
    end

    before do
      authenticated_in_hydra_as(owner)
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'responds 201 Created' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is a school-teacher' do
      authenticated_in_hydra_as(teacher)

      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds with the class members JSON array' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data.size).to eq(3)
    end

    it 'responds with the class member JSON' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)

      student_ids = data.pluck(:student_id)
      expect(student_ids).to eq(params[:student_ids])
    end

    it 'responds with the student JSON' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)

      response_students = data.pluck(:student)

      expect(response_students).to eq(student_attributes)
    end
  end

  context 'with invalid params' do
    let(:invalid_params) { { class_member: { student_ids: ' ' } } }

    before do
      authenticated_in_hydra_as(owner)
      stub_profile_api_list_school_students(school:, student_attributes: [])
    end

    it 'responds 422 Unprocessable Entity when params are missing' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds 422 Unprocessable Entity when params are invalid' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params: invalid_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns the error message in the operation response' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params: invalid_params)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:error]).to match(/No valid students provided/)
    end

    it 'responds 401 Unauthorized when no token is given' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", params:)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      school_class.update!(school_id: school.id)

      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
      teacher = create(:teacher, school:)
      authenticated_in_hydra_as(teacher)

      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
