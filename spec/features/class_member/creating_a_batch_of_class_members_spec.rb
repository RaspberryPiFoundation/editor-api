# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a class member', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }

  context 'with valid params' do
    let(:student_attributes) do
      students.map do |student|
        { id: student.id, name: student.name, username: student.username, email: student.email, sso_providers: [], type: 'student' }
      end
    end

    context 'when adding another teacher' do
      let(:another_teacher) { create(:teacher, school:) }
      let(:params) do
        {
          class_members: [{ user_id: another_teacher.id, type: 'teacher' }] + students.map { |student| { user_id: student.id, type: 'student' } }
        }
      end

      before do
        authenticated_in_hydra_as(teacher)
        stub_profile_api_list_school_students(school:, student_attributes:)
        stub_user_info_api_for(another_teacher)
      end

      it 'responds 200 OK' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        expect(response).to have_http_status(:ok)
      end

      it 'responds 200 OK when the user is a school-teacher' do
        authenticated_in_hydra_as(teacher)

        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        expect(response).to have_http_status(:ok)
      end

      it 'responds with the correct number of entries in the JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data.size).to eq(4)
      end

      it 'responds with the correct data in each entry of the JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        data = JSON.parse(response.body, symbolize_names: true)

        params[:class_members].each do |class_member|
          expect(data).to include({ success: true, user_id: class_member[:user_id] })
        end
      end
    end

    context 'when adding an owner as another teacher' do
      let(:owner_teacher) { create(:teacher, school:, id: create(:owner, school:).id) }

      let(:params) do
        {
          class_members: [{ user_id: owner_teacher.id, type: 'owner' }] + students.map { |student| { user_id: student.id, type: 'student' } }
        }
      end

      before do
        authenticated_in_hydra_as(teacher)
        stub_profile_api_list_school_students(school:, student_attributes:)
        stub_user_info_api_for(owner_teacher)
      end

      it 'responds 200 OK' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        expect(response).to have_http_status(:ok)
      end

      it 'responds 200 OK when the user is a school-teacher' do
        authenticated_in_hydra_as(teacher)

        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        expect(response).to have_http_status(:ok)
      end

      it 'responds with the correct number of entries in the JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data.size).to eq(4)
      end

      it 'responds with the class member JSON' do
        post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
        data = JSON.parse(response.body, symbolize_names: true)

        params[:class_members].each do |class_member|
          expect(data).to include({ success: true, user_id: class_member[:user_id] })
        end
      end
    end
  end

  context 'when not all members can be added to the class' do
    let(:params) do
      {
        class_members: students.map { |s| { user_id: s.id, type: 'student' } }
      }
    end
    let(:student_attributes) do
      students.map do |student|
        { id: student.id, name: student.name, username: student.username, type: 'student' }
      end
    end
    let(:existing_class_member_id) { students.first.id }

    before do
      authenticated_in_hydra_as(teacher)
      stub_profile_api_list_school_students(school:, student_attributes:)
      create(:class_student, school_class:, student_id: existing_class_member_id)
    end

    it 'returns 200 OK' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      expect(response).to have_http_status(:ok)
    end

    it 'returns a result for all members sent in the request' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data.length).to eq(students.length)
    end

    it 'returns error result for the members that could not be added' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)
      member_not_added = data.find { |result| result[:user_id] == existing_class_member_id && result[:success] == false }
      expect(member_not_added[:error]).to match(/Student has already been taken/)
    end

    it 'returns success result for members that could be added' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)

      success_results = data.select { |result| result[:success] }
      expect(success_results.length).to eq(2)
    end
  end

  context 'with invalid params' do
    before do
      authenticated_in_hydra_as(teacher)
    end

    it 'responds 400 Bad Request when params are missing' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:)
      expect(response).to have_http_status(:bad_request)
    end

    it 'responds 400 Bad Request when params are invalid' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params: { unknown_key: [] })
      expect(response).to have_http_status(:bad_request)
    end
  end

  context "with users that don't exist in Profile" do
    unknown_user_id = SecureRandom.uuid

    let(:invalid_params) do
      {
        class_members: [{ user_id: unknown_user_id }]
      }
    end

    before do
      authenticated_in_hydra_as(teacher)
      stub_user_info_api_for_unknown_users(user_id: unknown_user_id)
    end

    it 'responds 422 Unprocessable Entity' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params: invalid_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns the error message in the operation response' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", headers:, params: invalid_params)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:error]).to match(/No valid school members provided/)
    end
  end

  context 'when the user is not authorized' do
    let(:another_teacher) { create(:teacher, school:) }
    let(:params) do
      {
        class_members: [{ user_id: another_teacher.id, type: 'teacher' }] + students.map { |student| { user_id: student.id, type: 'student' } }
      }
    end

    it 'responds 401 Unauthorized when no token is given' do
      post("/api/schools/#{school.id}/classes/#{school_class.id}/members/batch", params:)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds 403 Forbidden when the user is a teacher from a different school' do
      authenticated_in_hydra_as(teacher)
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
