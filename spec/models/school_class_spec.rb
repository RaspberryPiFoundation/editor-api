# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'belongs to a school' do
      school_class = create(:school_class)
      expect(school_class.school).to be_a(School)
    end

    it 'has many members' do
      school_class = create(:school_class, members: [build(:class_member)])
      expect(school_class.members.size).to eq(1)
    end

    it 'has many lessons' do
      school_class = create(:school_class, lessons: [build(:lesson)])
      expect(school_class.lessons.size).to eq(1)
    end

    context 'when a school_class is destroyed' do
      let!(:school_class) { create(:school_class, members: [build(:class_member)], lessons: [build(:lesson)]) }

      it 'also destroys class members to avoid making them invalid' do
        expect { school_class.destroy! }.to change(ClassMember, :count).by(-1)
      end

      it 'does not destroy lessons' do
        expect { school_class.destroy! }.not_to change(Lesson, :count)
      end

      it 'nullifies school_class_id on lessons' do
        school_class.destroy!
        expect(Lesson.last.school_class).to be_nil
      end
    end
  end

  describe 'validations' do
    subject(:school_class) { build(:school_class) }

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
      school_class.teacher_id = ' '
      expect(school_class).to be_invalid
    end

    it 'requires a UUID teacher_id' do
      school_class.teacher_id = 'invalid'
      expect(school_class).to be_invalid
    end

    it 'requires a teacher that has the school-teacher role for the school' do
      stub_user_info_api_for_student
      school_class.teacher_id = '22222222-2222-2222-2222-222222222222' # school-student
      expect(school_class).to be_invalid
    end

    it 'requires a name' do
      school_class.name = ' '
      expect(school_class).to be_invalid
    end
  end

  describe '.teachers' do
    it 'returns User instances for the current scope' do
      create(:school_class)

      teacher = described_class.all.teachers.first
      expect(teacher.name).to eq('School Teacher')
    end

    it 'ignores members where no profile account exists' do
      create(:school_class, teacher_id: SecureRandom.uuid)

      teacher = described_class.all.teachers.first
      expect(teacher).to be_nil
    end

    it 'ignores members not included in the current scope' do
      create(:school_class)

      teacher = described_class.none.teachers.first
      expect(teacher).to be_nil
    end
  end

  describe '.with_teachers' do
    it 'returns an array of class members paired with their User instance' do
      school_class = create(:school_class)

      pair = described_class.all.with_teachers.first
      teacher = described_class.all.teachers.first

      expect(pair).to eq([school_class, teacher])
    end

    it 'returns nil values for members where no profile account exists' do
      school_class = create(:school_class, teacher_id: SecureRandom.uuid)

      pair = described_class.all.with_teachers.first
      expect(pair).to eq([school_class, nil])
    end

    it 'ignores members not included in the current scope' do
      create(:school_class)

      pair = described_class.none.with_teachers.first
      expect(pair).to be_nil
    end
  end

  describe '#with_teacher' do
    it 'returns the class member paired with their User instance' do
      school_class = create(:school_class)

      pair = school_class.with_teacher
      teacher = described_class.all.teachers.first

      expect(pair).to eq([school_class, teacher])
    end

    it 'returns a nil value if the member has no profile account' do
      school_class = create(:school_class, teacher_id: SecureRandom.uuid)

      pair = school_class.with_teacher
      expect(pair).to eq([school_class, nil])
    end
  end
end
