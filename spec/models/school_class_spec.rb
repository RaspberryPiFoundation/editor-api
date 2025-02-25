# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass, versioning: true do
  before do
    stub_user_info_api_for(teacher)
    # stub_user_info_api_for(second_teacher)
  end

  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  # let(:second_teacher) { create(:teacher, school:, name: 'Second Teacher') }
  let(:school) { create(:school) }

  describe 'associations' do
    it {is_expected.to belong_to(:school)}
    it {is_expected.to have_many(:students).dependent(:destroy)}
    it {is_expected.to have_many(:class_teachers).dependent(:destroy)}
    it {is_expected.to have_many(:lessons).dependent(:nullify)}
    it {is_expected.to belong_to(:school)}
  end

  describe 'validations' do
    subject(:school_class) { build(:school_class, teacher_ids: [teacher.id], school:) }

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
      school_class_without_teacher = build(:school_class, teacher_ids: [], school:)
      expect(school_class_without_teacher).to be_invalid
    end

    it 'requires a UUID teacher_id' do
      school_class_with_invalid_teacher = build(:school_class, teacher_ids: ['invalid'], school:)
      expect(school_class_with_invalid_teacher).to be_invalid
    end

    it 'requires a name' do
      school_class.name = ' '
      expect(school_class).to be_invalid
    end
  end

  describe '.teachers' do
    it 'returns User instances for the current scope' do
      create(:school_class, teacher_ids: [teacher.id], school:)

      teacher = described_class.all.teachers.first
      expect(teacher.name).to eq('School Teacher')
    end

    it 'ignores members where no profile account exists' do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      create(:school_class, school:, teacher_ids: [teacher.id])

      teacher = described_class.all.teachers.first
      expect(teacher).to be_nil
    end

    it 'ignores members not included in the current scope' do
      create(:school_class, teacher_ids: [teacher.id], school:)

      teacher = described_class.none.teachers.first
      expect(teacher).to be_nil
    end
  end

  describe '.with_teachers' do
    it 'returns an array of class teachers paired with their User instance' do
      school_class = create(:school_class, teacher_ids: [teacher.id], school:)

      pair = described_class.all.with_teachers.first
      teacher = described_class.all.teachers.first

      expect(pair).to eq([school_class, [teacher]])
    end

    it 'returns nil values for teachers where no profile account exists' do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])

      pair = described_class.all.with_teachers.first
      expect(pair).to eq([school_class, [nil]])
    end

    it 'ignores teachers not included in the current scope' do
      create(:school_class, teacher_ids: [teacher.id], school:)

      pair = described_class.none.with_teachers.first
      expect(pair).to be_nil
    end
  end

  # TODO: Test this in the case where there are multiple teachers
  describe '#with_teachers' do
    it 'returns the class teachers paired with their User instances' do
      school_class = create(:school_class, teacher_ids: [teacher.id], school:)
      school_class_with_teachers = school_class.with_teachers

      expect(school_class_with_teachers).to eq([school_class, [teacher]])
    end

    it 'skips user if the teacher has no profile account' do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])
      school_class_with_teachers = school_class.with_teachers
      
      expect(school_class_with_teachers).to eq([school_class, []])
    end
  end

  describe 'auditing' do
    subject(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }

    it 'enables auditing' do
      expect(school_class.versions.length).to(eq(1))
    end
  end
end
