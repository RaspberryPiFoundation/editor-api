# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'has many classes' do
      school = create(:school, classes: [build(:school_class), build(:school_class)])
      expect(school.classes.size).to eq(2)
    end

    context 'when a school is destroyed' do
      let!(:school_class) { build(:school_class, members: [build(:class_member)]) }
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

    it 'requires an owner that has the school-owner role for the school' do
      school.owner_id = '11111111-1111-1111-1111-111111111111' # school-teacher
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

    it 'does not require a reference' do
      create(:school, reference: nil)

      school.organisation_id = '99999999-9999-9999-9999-999999999999' # Satisfy the uniqueness validation.
      school.owner_id = '99999999-9999-9999-9999-999999999999' # Satisfy the school-owner validation.

      school.reference = nil
      expect(school).to be_valid
    end

    it 'requires references to be unique if provided' do
      school.reference = 'URN-123'
      school.save!

      duplicate_school = build(:school, reference: 'urn-123')
      expect(duplicate_school).to be_invalid
    end

    it 'requires an address_line_1' do
      school.address_line_1 = ' '
      expect(school).to be_invalid
    end

    it 'requires a municipality' do
      school.municipality = ' '
      expect(school).to be_invalid
    end

    it 'requires a country_code' do
      school.country_code = ' '
      expect(school).to be_invalid
    end

    it "requires an 'ISO 3166-1 alpha-2' country_code" do
      school.country_code = 'GBR'
      expect(school).to be_invalid
    end
  end

  describe '#school' do
    it 'returns a User instance for the owner_id of the school' do
      school = create(:school)
      expect(school.owner.name).to eq('School Owner')
    end

    it 'returns nil if no profile account exists' do
      school = create(:school, owner_id: '99999999-9999-9999-9999-999999999999')
      expect(school.owner).to be_nil
    end
  end
end
