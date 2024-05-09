# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role do
  describe 'validations' do
    subject(:role) { build(:role) }

    it 'has a valid default factory' do
      expect(role).to be_valid
    end

    it 'can save the default factory' do
      expect { role.save! }.not_to raise_error
    end

    it 'requires a school' do
      role.school = nil
      expect(role).to be_invalid
    end

    it 'requires a user_id' do
      role.user_id = nil
      expect(role).to be_invalid
    end

    it 'requires a role' do
      role.role = nil
      expect(role).to be_invalid
    end

    it 'requires a valid role' do
      expect { role.role = 'made-up-role' }.to raise_exception(ArgumentError, /is not a valid role/)
    end

    it 'requires role to be unique for the combination of user and school' do
      role.save
      duplicate_role = build(:role, school: role.school, user_id: role.user_id, role: role.role)
      expect(duplicate_role).to be_invalid
    end
  end
end
