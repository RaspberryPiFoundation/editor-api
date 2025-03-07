# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass, versioning: true do
  before do
    stub_user_info_api_for_users([teacher.id, second_teacher.id], users: [teacher, second_teacher])
  end

  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:second_teacher) { create(:teacher, school:, name: 'Second Teacher') }
  let(:school) { create(:school) }

  describe 'associations' do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:students).dependent(:destroy) }
    it { is_expected.to have_many(:teachers).dependent(:destroy) }
    it { is_expected.to have_many(:lessons).dependent(:nullify) }
  end

  describe 'nested attributes' do
    it 'accepts nested attributes for teachers' do
      school_class_attributes = attributes_for(:school_class).merge(
        teachers_attributes: [
          { teacher_id: teacher.id },
          { teacher_id: second_teacher.id }
        ]
      )

      school_class = described_class.new(school_class_attributes)
      expect(school_class.teachers.map(&:teacher_id)).to eq([teacher.id, second_teacher.id])
    end
  end

  describe 'validations' do
    subject(:school_class) { build(:school_class, teacher_ids: [teacher.id, second_teacher.id], school:) }

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

    it 'requires teacher_ids' do
      school_class_without_teacher = build(:school_class, teacher_ids: [], school:)
      expect(school_class_without_teacher).to be_invalid
    end

    it 'requires UUID teacher_ids' do
      school_class_with_invalid_teacher = build(:school_class, teacher_ids: ['invalid'], school:)
      expect(school_class_with_invalid_teacher).to be_invalid
    end

    it 'requires a name' do
      school_class.name = ' '
      expect(school_class).to be_invalid
    end

    it 'assigns class code before validating' do
      school_class.code = nil
      school_class.valid?
      expect(school_class.code).to match(/\d\d-\d\d-\d\d/)
    end

    it 'requires a unique class code within the same school' do
      school_class.save!
      school_class_with_duplicate_code = build(:school_class, school: school_class.school, code: school_class.code)
      school_class_with_duplicate_code.valid?
      expect(school_class_with_duplicate_code.errors[:code]).to include('has already been taken')
    end

    it 'permits a duplicate class code in different schools' do
      school_class.save!
      school_class_with_duplicate_code = build(:school_class, school: build(:school), code: school_class.code)
      expect(school_class_with_duplicate_code).to be_valid
    end

    it 'requires a valid class code format' do
      school_class.code = 'invalid'
      expect(school_class).to be_invalid
    end

    it 'accepts a valid class code format' do
      school_class.code = '12-34-56'
      expect(school_class).to be_valid
    end

    it 'does not allow the class code to be changed' do
      school_class.code = '12-34-56'
      school_class.save!
      school_class.code = '65-43-21'
      expect(school_class).to be_invalid
    end
  end

  describe '.teachers' do
    it 'returns User instances for the current scope' do
      create(:school_class, teacher_ids: [teacher.id, second_teacher.id], school:)

      teacher = described_class.all.teachers.first
      expect(teacher.name).to eq('School Teacher')
    end

    it 'ignores teachers where no profile account exists' do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      create(:school_class, school:, teacher_ids: [teacher.id])

      teacher = described_class.all.teachers.first
      expect(teacher).to be_nil
    end

    it 'ignores teachers not included in the current scope' do
      create(:school_class, teacher_ids: [teacher.id], school:)

      teacher = described_class.none.teachers.first
      expect(teacher).to be_nil
    end
  end

  describe '.with_teachers' do
    it 'returns an array of class teachers paired with their User instance' do
      school_class = create(:school_class, teacher_ids: [teacher.id, second_teacher.id], school:)

      pair = described_class.all.with_teachers.first
      teacher = described_class.all.teachers.first

      expect(pair).to eq([school_class, [teacher, second_teacher]])
    end

    it 'returns nil values for teachers where no profile account exists' do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])

      pair = described_class.all.with_teachers.first
      expect(pair).to eq([school_class, [nil]])
    end

    it 'ignores teachers not included in the current scope' do
      create(:school_class, teacher_ids: [teacher.id, second_teacher.id], school:)

      pair = described_class.none.with_teachers.first
      expect(pair).to be_nil
    end
  end

  describe '#with_teachers' do
    it 'returns the class teachers paired with their User instances' do
      school_class = create(:school_class, teacher_ids: [teacher.id, second_teacher.id], school:)
      school_class_with_teachers = school_class.with_teachers

      expect(school_class_with_teachers).to eq([school_class, [teacher, second_teacher]])
    end

    it 'skips user if the teacher has no profile account' do
      stub_user_info_api_for_unknown_users(user_id: teacher.id)
      stub_user_info_api_for(second_teacher)

      school_class = create(:school_class, school:, teacher_ids: [teacher.id, second_teacher.id])
      school_class_with_teachers = school_class.with_teachers

      expect(school_class_with_teachers).to eq([school_class, [second_teacher]])
    end
  end

  describe '#teacher_ids' do
    it 'returns an array of teacher ids' do
      school_class = create(:school_class, teacher_ids: [teacher.id, second_teacher.id], school:)
      expect(school_class.teacher_ids).to eq([teacher.id, second_teacher.id])
    end
  end

  describe '#assign_class_code' do
    it 'assigns a class code if not already present' do
      school_class = build(:school_class, code: nil, school:)
      school_class.assign_class_code
      expect(school_class.code).to match(/\d\d-\d\d-\d\d/)
    end

    it 'does not assign a class code if already present' do
      school_class = build(:school_class, code: '12-34-56', school:)
      school_class.assign_class_code
      expect(school_class.code).to eq('12-34-56')
    end

    it 'retries 5 times if the school code is not unique within the school' do
      school_class = create(:school_class, code: '12-34-56', school:)
      allow(ForEducationCodeGenerator).to receive(:generate).and_return(*([school.code] * 4), '00-00-00')
      another_school_class = create(:school_class, school: school_class.school, code: nil)
      another_school_class.assign_class_code
      expect(another_school_class.code).to eq('00-00-00')
    end

    it 'raises adds error if unique code cannot be generated in 5 retries' do
      school_class = create(:school_class, code: '12-34-56', school:)
      allow(ForEducationCodeGenerator).to receive(:generate).and_return(*([school.code] * 5))
      another_school_class = build(:school_class, school: school_class.school, code: nil)
      another_school_class.assign_class_code
      expect(another_school_class.errors[:code]).to include('could not be generated')
    end
  end

  describe 'auditing' do
    subject(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }

    it 'enables auditing' do
      expect(school_class.versions.length).to(eq(1))
    end
  end
end
