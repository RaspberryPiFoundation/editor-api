# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'belongs to a school_class' do
      class_member = create(:class_member)
      expect(class_member.school_class).to be_a(SchoolClass)
    end

    it 'belongs to a school (via school_class)' do
      class_member = create(:class_member)
      expect(class_member.school).to be_a(School)
    end
  end

  describe 'validations' do
    subject(:class_member) { build(:class_member) }

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
      class_member.student_id = '11111111-1111-1111-1111-111111111111' # school-teacher
      expect(class_member).to be_invalid
    end

    it 'requires a unique student_id within the school_class' do
      class_member.save!
      duplicate = build(:class_member, student_id: class_member.student_id, school_class: class_member.school_class)
      expect(duplicate).to be_invalid
    end
  end
end
