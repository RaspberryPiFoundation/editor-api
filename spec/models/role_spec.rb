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

    context 'when the student role exists for a user and school' do
      let(:user) { build(:user) }
      let(:school) { build(:school) }

      before do
        create(:student_role, user_id: user.id, school:)
      end

      it 'prevents an owner role being created for the user and school' do
        role = build(:owner_role, user_id: user.id, school:)
        expect(role).to be_invalid
      end

      it 'adds a message to explain why the owner role cannot be created' do
        role = build(:owner_role, user_id: user.id, school:)
        role.valid?
        expect(role.errors[:base]).to include('Cannot create owner role as this user already has the student role for this school')
      end

      it 'prevents a teacher role being created for the user and school' do
        role = build(:teacher_role, user_id: user.id, school:)
        expect(role).to be_invalid
      end

      it 'adds a message to explain why the teacher role cannot be created' do
        role = build(:teacher_role, user_id: user.id, school:)
        role.valid?
        expect(role.errors[:base]).to include('Cannot create teacher role as this user already has the student role for this school')
      end
    end

    context 'when the teacher role exists for a user and school' do
      let(:user) { build(:user) }
      let(:school) { build(:school) }

      before do
        create(:teacher_role, user_id: user.id, school:)
      end

      it 'allows an owner role to be created for the user and school' do
        expect(create(:owner_role, user_id: user.id, school:)).to be_persisted
      end

      it 'prevents a student role being created for the user and school' do
        role = build(:student_role, user_id: user.id, school:)
        expect(role).to be_invalid
      end

      it 'adds a message to explain why the student role cannot be created' do
        role = build(:student_role, user_id: user.id, school:)
        role.valid?
        expect(role.errors[:base]).to include('Cannot create student role as this user already has the teacher role for this school')
      end
    end

    context 'when the owner role exists for a user and school' do
      let(:user) { build(:user) }
      let(:school) { build(:school) }

      before do
        create(:owner_role, user_id: user.id, school:)
      end

      it 'allows a teacher role to be created for the user and school' do
        expect(create(:teacher_role, user_id: user.id, school:)).to be_persisted
      end

      it 'prevents a student role being created for the user and school' do
        role = build(:student_role, user_id: user.id, school:)
        expect(role).to be_invalid
      end

      it 'adds a message to explain why the student role cannot be created' do
        role = build(:student_role, user_id: user.id, school:)
        role.valid?
        expect(role.errors[:base]).to include('Cannot create student role as this user already has the owner role for this school')
      end
    end

    context 'when the owner and teacher roles exist for a user and school' do
      let(:user) { build(:user) }
      let(:school) { build(:school) }

      before do
        create(:owner_role, user_id: user.id, school:)
        create(:teacher_role, user_id: user.id, school:)
      end

      it 'prevents a student role being created for the user and school' do
        role = build(:student_role, user_id: user.id, school:)
        expect(role).to be_invalid
      end

      it 'adds a message to explain why the student role cannot be created' do
        role = build(:student_role, user_id: user.id, school:)
        role.valid?
        expect(role.errors[:base]).to include('Cannot create student role as this user already has the owner and teacher roles for this school')
      end
    end

    context 'when a user has a role within a school' do
      let(:user) { build(:user) }
      let(:school_1) { build(:school) }
      let(:school_2) { build(:school) }

      before do
        create(:role, user_id: user.id, school: school_1)
      end

      it 'prevents the user from having a role within a different school' do
        role = build(:role, user_id: user.id, school: school_2)
        expect(role).to be_invalid
      end

      it 'adds a message to explain that a user can only have roles within a single school' do
        role = build(:role, user_id: user.id, school: school_2)
        role.valid?
        expect(role.errors[:base]).to include('Cannot create role as this user already has a role in a different school')
      end
    end
  end
end
