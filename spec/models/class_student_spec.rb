# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassStudent, :versioning do
  before do
    stub_user_info_api_for(student)
  end

  let(:student) { create(:student, school:, name: 'School Student') }
  let(:school) { create(:school) }
  let(:school_class) { build(:school_class, teacher_ids: [teacher.id], school:) }
  let(:teacher) { create(:teacher, school:) }

  describe 'associations' do
    it 'belongs to a school_class' do
      class_student = create(:class_student, student_id: student.id, school_class:)
      expect(class_student.school_class).to be_a(SchoolClass)
    end

    it 'belongs to a school (via school_class)' do
      class_student = create(:class_student, student_id: student.id, school_class:)
      expect(class_student.school).to be_a(School)
    end
  end

  describe 'validations' do
    subject(:class_student) { build(:class_student, student_id: student.id, school_class:) }

    it 'has a valid default factory' do
      expect(class_student).to be_valid
    end

    it 'can save the default factory' do
      expect { class_student.save! }.not_to raise_error
    end

    it 'requires a school_class' do
      class_student.school_class = nil
      expect(class_student).not_to be_valid
    end

    it 'requires a student_id' do
      class_student.student_id = ' '
      expect(class_student).not_to be_valid
    end

    it 'requires a UUID student_id' do
      class_student.student_id = 'invalid'
      expect(class_student).not_to be_valid
    end

    it 'requires a student that has the school-student role for the school' do
      class_student.student = teacher
      expect(class_student).not_to be_valid
    end

    it 'requires a unique student_id within the school_class' do
      class_student.save!
      duplicate = build(:class_student, student_id: class_student.student_id, school_class: class_student.school_class)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'auditing' do
    subject(:class_student) { create(:class_student, student_id: student.id, school_class:) }

    it 'enables auditing' do
      expect(class_student.versions.length).to(eq(1))
    end
  end
end
