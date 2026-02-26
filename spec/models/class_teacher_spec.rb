# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassTeacher, :versioning do
  before do
    stub_user_info_api_for(teacher)
  end

  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:another_teacher) { create(:teacher, school:, name: 'Another Teacher') }
  let(:school) { create(:school) }
  let(:school_class) { build(:school_class, teacher_ids: [teacher.id], school:) }
  let(:student) { create(:student, school:) }

  describe 'associations' do
    subject(:class_teacher) { build(:class_teacher, teacher_id: another_teacher.id, school_class:) }

    it { is_expected.to belong_to(:school_class) }

    it 'belongs to a school via school_class' do
      expect(class_teacher.school).to eq(school)
    end
  end

  describe 'validations' do
    subject(:class_teacher) { build(:class_teacher, teacher_id: another_teacher.id, school_class:) }

    it 'has a valid default factory' do
      expect(class_teacher).to be_valid
    end

    it 'can save the default factory' do
      expect { class_teacher.save! }.not_to raise_error
    end

    it 'requires a school_class' do
      class_teacher.school_class = nil
      expect(class_teacher).not_to be_valid
    end

    it 'requires a teacher_id' do
      class_teacher.teacher_id = ' '
      expect(class_teacher).not_to be_valid
    end

    it 'requires a UUID teacher_id' do
      class_teacher.teacher_id = 'invalid'
      expect(class_teacher).not_to be_valid
    end

    it 'requires teacher to have the school-teacher role for the school' do
      class_teacher.teacher = student
      expect(class_teacher).not_to be_valid
    end

    it 'requires a unique teacher_id within the school_class' do
      class_teacher.save!
      duplicate = build(:class_teacher, teacher_id: class_teacher.teacher_id, school_class: class_teacher.school_class)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'auditing' do
    subject(:class_teacher) { create(:class_teacher, teacher_id: another_teacher.id, school_class:) }

    it 'enables auditing' do
      expect(class_teacher.versions.length).to(eq(1))
    end
  end
end
