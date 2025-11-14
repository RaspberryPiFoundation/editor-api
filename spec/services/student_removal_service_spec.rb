# frozen_string_literal: true

require 'rails_helper'

describe StudentRemovalService do
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school: school) }
  let(:teacher) { create(:teacher, school: school) }
  let(:student) { create(:student, school: school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id, owner.id], school: school) }
  let(:service) { described_class.new(school: school) }
  let(:empty_school) { create(:school) }

  before do
    allow(Project).to receive(:exists?).and_return(false)
    allow(ProfileApiClient).to receive(:delete_school_student)
    create(:class_student, student_id: student.id, school_class: school_class)
  end

  describe '#remove_student' do
    it 'removes student from classes and roles' do
      expect(Role.where(user_id: student.id, role: :student)).to exist
      expect(ClassStudent.where(student_id: student.id)).to exist

      service.remove_student(student.id)

      expect(ClassStudent.where(student_id: student.id)).not_to exist
      expect(Role.where(user_id: student.id, role: :student)).not_to exist
    end

    it 'raises NoSchoolError when school is nil' do
      service = described_class.new(school: nil)

      expect { service.remove_student(student.id) }.to raise_error(
        StudentRemovalService::NoSchoolError, 'School not found'
      )
    end

    it 'raises NoClassesError when school has no classes' do
      service = described_class.new(school: empty_school)

      expect { service.remove_student(student.id) }.to raise_error(
        StudentRemovalService::NoClassesError, 'School has no classes'
      )
    end

    it 'raises StudentHasProjectsError when student has projects' do
      allow(Project).to receive(:exists?).with(user_id: student.id).and_return(true)

      expect { service.remove_student(student.id) }.to raise_error(
        StudentRemovalService::StudentHasProjectsError, 'Student has existing projects'
      )
    end

    it 'raises NoopError when student has no roles or classes and raise_on_noop is true' do
      student_without_associations = create(:student, school: empty_school)
      service = described_class.new(school: school, raise_on_noop: true)

      expect { service.remove_student(student_without_associations.id) }.to raise_error(
        StudentRemovalService::NoopError, 'Student has no roles or class assignments to remove'
      )
    end

    it 'does not raise NoopError when remove_from_profile is true (even with raise_on_noop true)' do
      student_without_associations = create(:student, school: empty_school)
      service = described_class.new(
        school: school,
        raise_on_noop: true,
        remove_from_profile: true,
        token: 'abc123'
      )

      expect { service.remove_student(student_without_associations.id) }.not_to raise_error
    end

    it 'calls ProfileApiClient when remove_from_profile is true and token is present' do
      token = 'abc123'
      service = described_class.new(school: school, remove_from_profile: true, token: token)

      service.remove_student(student.id)

      expect(ProfileApiClient).to have_received(:delete_school_student).with(
        token: token,
        school_id: school.id,
        student_id: student.id
      )
    end

    it 'does not call ProfileApiClient when remove_from_profile is false' do
      service = described_class.new(school: school, remove_from_profile: false, token: 'abc123')

      service.remove_student(student.id)

      expect(ProfileApiClient).not_to have_received(:delete_school_student)
    end

    it 'does not call ProfileApiClient when token is missing' do
      service = described_class.new(school: school, remove_from_profile: true, token: nil)

      service.remove_student(student.id)

      expect(ProfileApiClient).not_to have_received(:delete_school_student)
    end
  end
end
