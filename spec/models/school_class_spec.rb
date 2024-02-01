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
end
