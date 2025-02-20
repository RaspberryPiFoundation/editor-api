# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember, versioning: true do
  before do
    stub_user_info_api_for(student)
  end

  let(:student) { create(:student, school:, name: 'School Student') }
  let(:school) { create(:school) }
  let(:school_class) { build(:school_class, teacher_id: teacher.id, school:) }
  let(:teacher) { create(:teacher, school:) }

  describe 'associations' do
    it 'belongs to a school_class' do
      class_member = create(:class_student, student_id: student.id, school_class:)
      expect(class_member.school_class).to be_a(SchoolClass)
    end

    it 'belongs to a school (via school_class)' do
      class_member = create(:class_student, student_id: student.id, school_class:)
      expect(class_member.school).to be_a(School)
    end
  end

  describe 'validations' do
    subject(:class_member) { build(:class_member, student_id: student.id, school_class:) }

    it 'has a valid default factory' do
      expect(class_member).to be_valid
    end

    it 'can save the default factory' do
      expect { class_member.save! }.not_to raise_error
    end

    it 'requires a school_class' do
      class_member.school_class = nil
      expect(class_member).to be_invalid
    end

    it 'requires a student_id' do
      class_member.student_id = ' '
      expect(class_member).to be_invalid
    end

    it 'requires a UUID student_id' do
      class_member.student_id = 'invalid'
      expect(class_member).to be_invalid
    end

    it 'requires a student that has the school-student role for the school' do
      class_member.student = teacher
      expect(class_member).to be_invalid
    end

    it 'requires a unique student_id within the school_class' do
      class_member.save!
      duplicate = build(:class_member, student_id: class_member.student_id, school_class: class_member.school_class)
      expect(duplicate).to be_invalid
    end
  end

  describe 'auditing' do
    subject(:class_member) { create(:class_student, student_id: student.id, school_class:) }

    it 'enables auditing' do
      expect(class_member.versions.length).to(eq(1))
    end
  end
end
