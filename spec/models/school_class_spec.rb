# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'belongs to a school' do
      school_class = create(:school_class)
      expect(school_class.school).to be_a(School)
    end

    it 'has many members' do
      school_class = create(:school_class, members: [build(:class_member)])
      expect(school_class.members.size).to eq(1)
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

    it 'requires a teacher that has the school-teacher role for the school' do
      school_class.teacher_id = '22222222-2222-2222-2222-222222222222' # school-student
      expect(school_class).to be_invalid
    end

    it 'requires a name' do
      school_class.name = ' '
      expect(school_class).to be_invalid
    end
  end

  describe '#teacher' do
    it 'returns a User instance for the teacher_id of the class' do
      school_class = create(:school_class, teacher_id: '11111111-1111-1111-1111-111111111111')
      expect(school_class.teacher.name).to eq('School Teacher')
    end

    it 'returns nil if no profile account exists' do
      school_class = create(:school_class, teacher_id: SecureRandom.uuid)
      expect(school_class.teacher).to be_nil
    end
  end
end
