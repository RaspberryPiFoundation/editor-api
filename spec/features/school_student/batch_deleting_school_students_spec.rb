# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch deleting school students', type: :request do
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school: school) }
  let(:teacher) { create(:teacher, school: school) }
  let(:school_class) { create(:school_class, school: school, teacher_ids: [teacher.id]) }
  let(:student_1) { create(:student, school: school) }
  let(:student_2) { create(:student, school: school) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  before do
    authenticated_in_hydra_as(owner)
    stub_profile_api_create_safeguarding_flag
    create(:class_student, student_id: student_1.id, school_class: school_class)
    create(:class_student, student_id: student_2.id, school_class: school_class)
  end

  describe 'DELETE /api/schools/:school_id/students/batch' do
    before do
      stub_profile_api_delete_school_student
    end

    it 'calls ProfileApiClient to delete each student from the profile service' do
      delete "/api/schools/#{school.id}/students/batch",
             params: { student_ids: [student_1.id, student_2.id] },
             headers: headers

      expect(response).to have_http_status(:ok)
      expect(ProfileApiClient).to have_received(:delete_school_student).with(token: UserProfileMock::TOKEN, school_id: school.id, student_id: student_1.id)
      expect(ProfileApiClient).to have_received(:delete_school_student).with(token: UserProfileMock::TOKEN, school_id: school.id, student_id: student_2.id)
    end

    it 'deletes all students and their projects' do
      project_1 = create(:project, user_id: student_1.id)
      project_2 = create(:project, user_id: student_2.id)

      expect(ClassStudent.where(student_id: student_1.id)).to exist
      expect(ClassStudent.where(student_id: student_2.id)).to exist
      expect(Project.where(id: project_1.id)).to exist
      expect(Project.where(id: project_2.id)).to exist

      delete "/api/schools/#{school.id}/students/batch",
             params: { student_ids: [student_1.id, student_2.id] },
             headers: headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['results'].size).to eq(2)
      expect(json['results'].all? { |r| r['error'].nil? }).to be true

      # Verify students removed from classes
      expect(ClassStudent.where(student_id: student_1.id)).not_to exist
      expect(ClassStudent.where(student_id: student_2.id)).not_to exist

      # Verify projects deleted
      expect(Project.where(id: project_1.id)).not_to exist
      expect(Project.where(id: project_2.id)).not_to exist
    end

    it 'responds 403 Forbidden when the user is a school-teacher' do
      authenticated_in_hydra_as(teacher)

      delete "/api/schools/#{school.id}/students/batch",
             params: { student_ids: [student_1.id, student_2.id] },
             headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns error when no student IDs provided' do
      delete "/api/schools/#{school.id}/students/batch",
             headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('No student IDs provided')
    end

    context 'when validating input parameters' do
      it 'removes duplicate student IDs before processing' do
        duplicate_ids = [student_1.id, student_1.id, student_2.id, student_2.id, student_1.id]

        delete "/api/schools/#{school.id}/students/batch",
               params: { student_ids: duplicate_ids },
               headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        # Should only process 2 unique students
        expect(json['results'].size).to eq(2)
        expect(json['results'].pluck('user_id')).to contain_exactly(student_1.id, student_2.id)
      end
    end

    context 'when handling non-existent student IDs' do
      it 'skips non-existent students and processes valid ones' do
        non_existent_id = SecureRandom.uuid
        project_1 = create(:project, user_id: student_1.id)

        delete "/api/schools/#{school.id}/students/batch",
               params: { student_ids: [student_1.id, non_existent_id] },
               headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['results'].size).to eq(2)

        # Valid student should be removed
        valid_result = json['results'].find { |r| r['user_id'] == student_1.id }
        expect(valid_result['error']).to be_nil
        expect(Project.exists?(project_1.id)).to be false
        expect(ClassStudent.where(student_id: student_1.id)).not_to exist

        # Non-existent student should be skipped
        skipped_result = json['results'].find { |r| r['user_id'] == non_existent_id }
        expect(skipped_result['skipped']).to be true
        expect(skipped_result['reason']).to eq('no_role_in_school')
      end

      it 'returns success when all IDs are non-existent' do
        non_existent_id_1 = SecureRandom.uuid
        non_existent_id_2 = SecureRandom.uuid

        delete "/api/schools/#{school.id}/students/batch",
               params: { student_ids: [non_existent_id_1, non_existent_id_2] },
               headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['results'].size).to eq(2)
        expect(json['results'].all? { |r| r['skipped'] == true }).to be true
        expect(json['results'].all? { |r| r['reason'] == 'no_role_in_school' }).to be true
      end
    end

    context 'when handling students from different schools' do
      let(:other_school) { create(:school) }
      let(:other_school_owner) { create(:owner, school: other_school) }
      let(:other_student) { create(:student, school: other_school) }

      before do
        other_school_class = create(:school_class, school: other_school)
        create(:class_student, student_id: other_student.id, school_class: other_school_class)
      end

      it 'skips students from different schools and processes own students' do
        project_1 = create(:project, user_id: student_1.id)
        other_project = create(:project, user_id: other_student.id)

        delete "/api/schools/#{school.id}/students/batch",
               params: { student_ids: [student_1.id, other_student.id] },
               headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['results'].size).to eq(2)

        # Own student should be removed
        valid_result = json['results'].find { |r| r['user_id'] == student_1.id }
        expect(valid_result['error']).to be_nil
        expect(Project.exists?(project_1.id)).to be false
        expect(ClassStudent.where(student_id: student_1.id)).not_to exist

        # Other school's student should be skipped
        skipped_result = json['results'].find { |r| r['user_id'] == other_student.id }
        expect(skipped_result['skipped']).to be true
        expect(skipped_result['reason']).to eq('no_role_in_school')

        # Other school's student data should remain intact
        expect(Project.exists?(other_project.id)).to be true
        expect(Role.where(user_id: other_student.id, school_id: other_school.id, role: :student)).to exist
      end
    end

    context 'when handling partial failures' do
      it 'returns 200 OK with error details when some deletions fail' do
        project_2 = create(:project, user_id: student_2.id)

        # Simulate ProfileApiClient failure for one student
        allow(ProfileApiClient).to receive(:delete_school_student).with(
          token: UserProfileMock::TOKEN,
          school_id: school.id,
          student_id: student_1.id
        ).and_raise(StandardError, 'Profile API error')

        allow(ProfileApiClient).to receive(:delete_school_student).with(
          token: UserProfileMock::TOKEN,
          school_id: school.id,
          student_id: student_2.id
        ).and_return(true)

        delete "/api/schools/#{school.id}/students/batch",
               params: { student_ids: [student_1.id, student_2.id] },
               headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['results'].size).to eq(2)
        expect(json['error']).to eq('1 student(s) failed to be removed')

        # First student should have error
        failed_result = json['results'].find { |r| r['user_id'] == student_1.id }
        expect(failed_result['error']).to match(/StandardError: Profile API error/)

        # Second student should succeed
        success_result = json['results'].find { |r| r['user_id'] == student_2.id }
        expect(success_result['error']).to be_nil
        expect(Project.exists?(project_2.id)).to be false
        expect(ClassStudent.where(student_id: student_2.id)).not_to exist
      end

      it 'reports correct error count when multiple deletions fail' do
        allow(ProfileApiClient).to receive(:delete_school_student).and_raise(StandardError, 'Profile API down')

        delete "/api/schools/#{school.id}/students/batch",
               params: { student_ids: [student_1.id, student_2.id] },
               headers: headers

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['results'].size).to eq(2)
        expect(json['error']).to eq('2 student(s) failed to be removed')
        expect(json['results'].all? { |r| r['error'].present? }).to be true
      end
    end
  end
end
