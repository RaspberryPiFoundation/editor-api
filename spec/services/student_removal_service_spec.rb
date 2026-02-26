# frozen_string_literal: true

require 'rails_helper'

describe StudentRemovalService do
  let(:school) { create(:school) }
  let(:other_school) { create(:school) }
  let(:owner) { create(:owner, school: school) }
  let(:teacher) { create(:teacher, school: school) }
  let(:student) { create(:student, school: school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id, owner.id], school: school) }
  let(:service) { described_class.new(students: [student.id], school: school) }

  before do
    allow(ProfileApiClient).to receive(:delete_school_student)
    create(:class_student, student_id: student.id, school_class: school_class)
  end

  describe '#remove_students' do
    context 'when student has a role in the school' do
      it 'removes student from classes, roles, and deletes all projects' do
        school_project = create(:project, user_id: student.id, school: school)
        personal_project = create(:project, user_id: student.id, school: nil)

        expect(Role.where(user_id: student.id, role: :student, school_id: school.id)).to exist
        expect(ClassStudent.where(student_id: student.id)).to exist
        expect(Project.where(user_id: student.id)).to exist

        results = service.remove_students

        expect(results.first[:user_id]).to eq(student.id)
        expect(results.first[:error]).to be_nil
        expect(ClassStudent.where(student_id: student.id)).not_to exist
        expect(Role.where(user_id: student.id, role: :student, school_id: school.id)).not_to exist
        expect(Project.exists?(school_project.id)).to be false
        expect(Project.exists?(personal_project.id)).to be false
      end

      it 'only deletes class assignments for the current school' do
        # Create a different student for the other school
        other_student = create(:student, school: other_school)
        other_school_class = create(:school_class, school: other_school)
        other_class_assignment = create(:class_student, student_id: other_student.id, school_class: other_school_class)

        # Original student should be removed from this school only
        results = service.remove_students

        expect(results.first[:error]).to be_nil
        expect(ClassStudent.joins(:school_class).where(student_id: student.id, school_class: { school_id: school.id })).not_to exist
        # Other student's assignment should remain
        expect(ClassStudent.exists?(other_class_assignment.id)).to be true
      end

      it 'only deletes roles for the current school' do
        # Create a different student for the other school
        other_student = create(:student, school: other_school)

        results = service.remove_students

        expect(results.first[:error]).to be_nil
        expect(Role.where(user_id: student.id, role: :student, school_id: school.id)).not_to exist
        # Other student's role should remain
        expect(Role.where(user_id: other_student.id, school_id: other_school.id)).to exist
      end

      it 'deletes all projects for the user regardless of school' do
        school_project = create(:project, user_id: student.id, school: school)
        personal_project = create(:project, user_id: student.id, school: nil)

        # Create a different student for the other school
        other_student = create(:student, school: other_school)
        other_school_project = create(:project, user_id: other_student.id, school: other_school)

        results = service.remove_students

        expect(results.first[:error]).to be_nil
        expect(Project.exists?(school_project.id)).to be false
        expect(Project.exists?(personal_project.id)).to be false
        # Other student's project should remain
        expect(Project.exists?(other_school_project.id)).to be true
      end

      it 'deletes school project transitions when deleting projects' do
        project = create(:project, user_id: student.id, school: school)
        school_project = project.school_project

        # Transition the project to create SchoolProjectTransition records
        school_project.transition_status_to!(:submitted, student.id)
        school_project.transition_status_to!(:returned, teacher.id)

        results = service.remove_students

        expect(results.first[:error]).to be_nil
        expect(Project.exists?(project.id)).to be false
        expect(SchoolProject.exists?(school_project.id)).to be false
        expect(SchoolProjectTransition.where(school_project_id: school_project.id).count).to eq(0)
      end
    end

    context 'when student does not have a role in the school' do
      let(:student_without_role) { create(:user) }
      let(:service) { described_class.new(students: [student_without_role.id], school: school) }

      it 'returns a skipped entry with reason' do
        results = service.remove_students

        expect(results.length).to eq(1)
        expect(results.first[:user_id]).to eq(student_without_role.id)
        expect(results.first[:skipped]).to be true
        expect(results.first[:reason]).to eq('no_role_in_school')
      end
    end

    context 'when processing multiple students' do
      let(:second_student) { create(:student, school: school) }
      let(:student_without_role) { create(:user) }
      let(:service) { described_class.new(students: [student.id, second_student.id, student_without_role.id], school: school) }

      before do
        create(:class_student, student_id: second_student.id, school_class: school_class)
      end

      it 'processes students with roles and returns skipped entry for those without' do
        create(:project, user_id: student.id, school: school)
        create(:project, user_id: second_student.id, school: school)

        results = service.remove_students

        expect(results.length).to eq(3)
        expect(results.pluck(:user_id)).to contain_exactly(student.id, second_student.id, student_without_role.id)
        expect(Role.where(user_id: student.id, school: school, role: :student)).not_to exist
        expect(Role.where(user_id: second_student.id, school: school, role: :student)).not_to exist

        skipped_result = results.find { |r| r[:user_id] == student_without_role.id }
        expect(skipped_result[:skipped]).to be true
        expect(skipped_result[:reason]).to eq('no_role_in_school')
      end
    end

    context 'with profile API integration' do
      it 'calls ProfileApiClient if remove_from_profile is true and token is present' do
        token = 'abc123'
        service = described_class.new(students: [student.id], school: school, remove_from_profile: true, token: token)
        service.remove_students
        expect(ProfileApiClient).to have_received(:delete_school_student).with(token: token, school_id: school.id, student_id: student.id)
      end

      it 'does not call ProfileApiClient if remove_from_profile is false' do
        service = described_class.new(students: [student.id], school: school, remove_from_profile: false, token: 'token')
        service.remove_students
        expect(ProfileApiClient).not_to have_received(:delete_school_student)
      end

      it 'does not call ProfileApiClient if token is not present' do
        service = described_class.new(students: [student.id], school: school, remove_from_profile: true, token: nil)
        service.remove_students
        expect(ProfileApiClient).not_to have_received(:delete_school_student)
      end

      it 'rolls back database changes if ProfileApiClient call fails' do
        token = 'abc123'
        project = create(:project, user_id: student.id, school: school)

        # Stub ProfileApiClient to raise an error
        allow(ProfileApiClient).to receive(:delete_school_student).and_raise(StandardError, 'Profile API failure')

        service = described_class.new(students: [student.id], school: school, remove_from_profile: true, token: token)
        results = service.remove_students

        # Should have error in result
        expect(results.first[:error]).to match(/Profile API failure/)

        # Database changes should have been rolled back
        expect(Project.exists?(project.id)).to be true
        expect(ClassStudent.where(student_id: student.id)).to exist
        expect(Role.where(user_id: student.id, school_id: school.id, role: :student)).to exist
      end
    end

    context 'when handling errors' do
      it 'handles errors gracefully' do
        allow(ClassStudent).to receive(:joins).and_raise(StandardError, 'fail')
        results = service.remove_students
        expect(results.first[:error]).to match(/StandardError: fail/)
      end

      it 'continues processing other students after an error' do
        second_student = create(:student, school: school)
        service = described_class.new(students: [student.id, second_student.id], school: school)

        # Mock to raise error on first student's projects
        projects_relation = instance_double(ActiveRecord::Relation)
        allow(projects_relation).to receive(:destroy_all).and_raise(StandardError, 'fail')
        allow(Project).to receive(:where).with(user_id: student.id).and_return(projects_relation)
        allow(Project).to receive(:where).with(user_id: second_student.id).and_call_original

        results = service.remove_students

        expect(results.length).to eq(2)
        expect(results.first[:error]).to match(/StandardError/)
        # Second student should succeed
        expect(Role.where(user_id: second_student.id, school: school, role: :student)).not_to exist
      end
    end
  end
end
