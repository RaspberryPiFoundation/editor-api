# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  describe 'associations' do
    it 'has many classes' do
      school = create(:school, classes: [build(:school_class), build(:school_class)])
      expect(school.classes.size).to eq(2)
    end

    context 'when a school is destroyed' do
      let!(:school_class) { create(:school_class, members: [build(:class_member)]) }
      let!(:school) { create(:school, classes: [school_class]) }

      it 'also destroys school classes to avoid making them invalid' do
        expect { school.destroy! }.to change(SchoolClass, :count).by(-1)
      end

      it 'also destroys class members to avoid making them invalid' do
        expect { school.destroy! }.to change(ClassMember, :count).by(-1)
      end
    end
  end

  describe 'validations' do
    subject(:school) { build(:school) }

    it 'has a valid default factory' do
      expect(school).to be_valid
    end

    it 'can save the default factory' do
      expect { school.save! }.not_to raise_error
    end

    it 'requires an organisation_id' do
      school.organisation_id = ' '
      expect(school).to be_invalid
    end

    it 'requires a UUID organisation_id' do
      school.organisation_id = 'invalid'
      expect(school).to be_invalid
    end

    it 'requires an owner_id' do
      school.owner_id = ' '
      expect(school).to be_invalid
    end

    it 'requires a UUID owner_id' do
      school.owner_id = 'invalid'
      expect(school).to be_invalid
    end

    it 'requires a unique organisation_id' do
      school.save!

      duplicate_id = school.organisation_id.upcase
      duplicate_school = build(:school, organisation_id: duplicate_id)

      expect(duplicate_school).to be_invalid
    end

    it 'requires a name' do
      school.name = ' '
      expect(school).to be_invalid
    end
  end
end
