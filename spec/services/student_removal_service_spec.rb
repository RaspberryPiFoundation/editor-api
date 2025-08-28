# frozen_string_literal: true

require 'rails_helper'

describe StudentRemovalService do
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school: school) }
  let(:teacher) { create(:teacher, school: school) }
  let(:student) { create(:student, school: school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id, owner.id], school: school) }
  let(:service) { described_class.new(students: [student.id], school: school) }

  before do
    allow(Project).to receive(:where).and_return([])
    allow(ProfileApiClient).to receive(:delete_school_student)
    create(:class_student, student_id: student.id, school_class: school_class)
  end

  it 'removes student from classes and roles' do
    expect(Role.where(user_id: student.id, role: :student)).to exist
    expect(ClassStudent.where(student_id: student.id)).to exist
    results = service.remove_students
    expect(results.first[:user_id]).to eq(student.id)
    expect(results.first[:skipped]).to be_nil
    expect(ClassStudent.where(student_id: student.id)).not_to exist
    expect(Role.where(user_id: student.id, role: :student)).not_to exist
  end

  it 'skips removal if student has projects' do
    allow(Project).to receive(:where).and_return([instance_double(Project)])
    results = service.remove_students
    expect(results.first[:skipped]).to be true
  end

  it 'calls ProfileApiClient if remove_from_profile is true and token is present' do
    token = 'abc123'
    service = described_class.new(students: [student.id], school: school, remove_from_profile: true, token: token)
    service.remove_students
    expect(ProfileApiClient).to have_received(:delete_school_student).with(token: token, school_id: school.id, student_id: student.id)
  end

  it 'handles errors gracefully' do
    allow(ClassStudent).to receive(:where).and_raise(StandardError, 'fail')
    results = service.remove_students
    expect(results.first[:error]).to match(/StandardError: fail/)
  end
end
