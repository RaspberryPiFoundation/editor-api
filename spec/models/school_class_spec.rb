# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass do
  describe 'associations' do
    it 'has many members' do
      school_class = create(:school_class, members: [build(:class_member), build(:class_member)])
      expect(school_class.members.size).to eq(2)
    end

    context 'when a school_class is destroyed' do
      let!(:school_class) { create(:school_class, members: [build(:class_member)]) }

      it 'also destroys class members to avoid making them invalid' do
        expect { school_class.destroy! }.to change(ClassMember, :count).by(-1)
      end
    end
  end

  describe 'validations' do
    subject(:school_class) { build(:school_class) }

    it 'has a valid default factory' do
      expect(school_class).to be_valid
    end

    it 'can save the default factory' do
      expect { school_class.save! }.not_to raise_error
    end

    it 'requires a school' do
      school_class.school = nil
      expect(school_class).to be_invalid
    end

    it 'requires a teacher_id' do
      school_class.teacher_id = ' '
      expect(school_class).to be_invalid
    end

    it 'requires a UUID teacher_id' do
      school_class.teacher_id = 'invalid'
      expect(school_class).to be_invalid
    end

    it 'requires a name' do
      school_class.name = ' '
      expect(school_class).to be_invalid
    end
  end

  describe '#teacher' do
    before do
      stub_userinfo_api
    end

    it 'returns a User instance for the teacher_id of the class' do
      school_class = create(:school_class, teacher_id: '11111111-1111-1111-1111-111111111111')
      expect(school_class.teacher.name).to eq('School Teacher')
    end

    it 'returns nil if no profile account exists' do
      school_class = create(:school_class, teacher_id: '99999999-9999-9999-9999-999999999999')
      expect(school_class.teacher).to be_nil
    end
  end

  describe '#students' do
    before do
      stub_userinfo_api
    end

    it 'returns User instances for members of the class' do
      member = build(:class_member, student_id: '22222222-2222-2222-2222-222222222222')
      school_class = create(:school_class, members: [member])

      student = school_class.students.first
      expect(student.name).to eq('School Student')
    end

    it 'ignores members where no profile account exists' do
      member = build(:class_member, student_id: '99999999-9999-9999-9999-999999999999')
      school_class = create(:school_class, members: [member])

      student = school_class.students.first
      expect(student).to be_nil
    end
  end
end
