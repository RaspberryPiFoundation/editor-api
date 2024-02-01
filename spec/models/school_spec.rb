# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  describe 'validations' do
    subject(:school) { build(:school) }

    it 'has a valid default factory' do
      expect(school).to be_valid
    end

    it 'can save the default factory' do
      expect { school.save! }.not_to raise_error
    end

    it 'is invalid if no organisation_id' do
      school.organisation_id = ' '
      expect(school).to be_invalid
    end

    it 'is invalid if organisation_id is not a UUID' do
      school.organisation_id = 'invalid'
      expect(school).to be_invalid
    end

    it 'is invalid if no name' do
      school.name = ' '
      expect(school).to be_invalid
    end
  end
end
