# frozen_string_literal: true

require 'rails_helper'

describe StudentRoleService do
  let(:school) { create(:school) }

  describe '.ensure_student_role' do
    it 'does not create a role for a user without a student account' do
      user = build(:user, school_id: school.id)

      expect { described_class.ensure_student_role(user) }.not_to change(Role, :count)
    end

    it 'creates a student role in the school of a student account' do
      user = build(:student, school_id: school.id)

      described_class.ensure_student_role(user)

      expect(Role.student.find_by(user_id: user.id, school_id: school.id)).to be_present
    end

    it 'does not create another role when the student role already exists' do
      user = build(:student, school_id: school.id)
      create(:student_role, user_id: user.id, school:)

      expect { described_class.ensure_student_role(user) }.not_to change(Role, :count)
    end
  end
end
