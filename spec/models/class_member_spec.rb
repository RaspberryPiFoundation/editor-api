# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember do
  before do
    stub_user_info_api_for(student)
  end

  let(:student) { create(:student, school:, name: 'School Student') }
  let(:school) { create(:school) }
  let(:school_class) { build(:school_class, teacher_id: teacher.id, school:) }
  let(:teacher) { create(:teacher, school:) }

  describe 'associations' do
    it 'belongs to a school_class' do
      class_member = create(:class_member, student_id: student.id, school_class:)
      expect(class_member.school_class).to be_a(SchoolClass)
    end

    it 'belongs to a school (via school_class)' do
      class_member = create(:class_member, student_id: student.id, school_class:)
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
      class_member.student_id = teacher.id
      expect(class_member).to be_invalid
    end

    it 'requires a unique student_id within the school_class' do
      class_member.save!
      duplicate = build(:class_member, student_id: class_member.student_id, school_class: class_member.school_class)
      expect(duplicate).to be_invalid
    end
  end

  describe '.students' do
    it 'returns User instances for the current scope' do
      create(:class_member, student_id: student.id, school_class:)

      student = described_class.all.students.first
      expect(student.name).to eq('School Student')
    end

    it 'ignores members where no profile account exists' do
      student = create(:student, school:)
      stub_user_info_api_for_unknown_users(user_id: student.id)
      create(:class_member, student_id: student.id, school_class:)

      student = described_class.all.students.first
      expect(student).to be_nil
    end

    it 'ignores members not included in the current scope' do
      create(:class_member, student_id: student.id, school_class:)

      student = described_class.none.students.first
      expect(student).to be_nil
    end
  end

  describe '.with_students' do
    it 'returns an array of class members paired with their User instance' do
      class_member = create(:class_member, student_id: student.id, school_class:)

      pair = described_class.all.with_students.first
      student = described_class.all.students.first

      expect(pair).to eq([class_member, student])
    end

    it 'returns nil values for members where no profile account exists' do
      student = create(:student, school:)
      stub_user_info_api_for_unknown_users(user_id: student.id)
      class_member = create(:class_member, student_id: student.id, school_class:)

      pair = described_class.all.with_students.first
      expect(pair).to eq([class_member, nil])
    end

    it 'ignores members not included in the current scope' do
      create(:class_member, student_id: student.id, school_class:)

      pair = described_class.none.with_students.first
      expect(pair).to be_nil
    end
  end

  describe '#with_student' do
    it 'returns the class member paired with their User instance' do
      class_member = create(:class_member, student_id: student.id, school_class:)

      pair = class_member.with_student
      student = described_class.all.students.first

      expect(pair).to eq([class_member, student])
    end

    it 'returns a nil value if the member has no profile account' do
      student = create(:student, school:)
      stub_user_info_api_for_unknown_users(user_id: student.id)
      class_member = create(:class_member, student_id: student.id, school_class:)

      pair = class_member.with_student
      expect(pair).to eq([class_member, nil])
    end
  end
end
