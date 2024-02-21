# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'optionally belongs to a school (library)' do
      lesson = create(:lesson, school: build(:school))
      expect(lesson.school).to be_a(School)
    end

    it 'optionally belongs to a school class' do
      school_class = create(:school_class)

      lesson = create(:lesson, school_class:, school: school_class.school)
      expect(lesson.school_class).to be_a(SchoolClass)
    end
  end

  describe 'validations' do
    subject(:lesson) { build(:lesson) }

    it 'has a valid default factory' do
      expect(lesson).to be_valid
    end

    it 'can save the default factory' do
      expect { lesson.save! }.not_to raise_error
    end

    it 'requires a user_id' do
      lesson.user_id = ' '
      expect(lesson).to be_invalid
    end

    it 'requires a UUID user_id' do
      lesson.user_id = 'invalid'
      expect(lesson).to be_invalid
    end

    context 'when the lesson has a school' do
      before do
        lesson.update!(school_class: create(:school_class))
      end

      it 'requires a user that has the school-owner or school-teacher role for the school' do
        lesson.user_id = '22222222-2222-2222-2222-222222222222' # school-student
        expect(lesson).to be_invalid
      end
    end

    it 'requires a name' do
      lesson.name = ' '
      expect(lesson).to be_invalid
    end

    it 'requires a visibility' do
      lesson.visibility = ' '
      expect(lesson).to be_invalid
    end

    it "requires a visibility that is either 'private', 'teachers', 'students' or 'public'" do
      lesson.visibility = 'invalid'
      expect(lesson).to be_invalid
    end
  end

  describe '#school' do
    it 'is set from the school_class' do
      lesson = create(:lesson, school_class: build(:school_class))
      expect(lesson.school).to eq(lesson.school_class.school)
    end

    it 'is not nullified when there is no school_class' do
      lesson = create(:lesson, school: build(:school))
      expect(lesson.school).not_to eq(lesson.school_class&.school)
    end
  end

  describe '.users' do
    it 'returns User instances for the current scope' do
      create(:lesson)

      user = described_class.all.users.first
      expect(user.name).to eq('School Teacher')
    end

    it 'ignores members where no profile account exists' do
      create(:lesson, user_id: SecureRandom.uuid)

      user = described_class.all.users.first
      expect(user).to be_nil
    end

    it 'ignores members not included in the current scope' do
      create(:lesson)

      user = described_class.none.users.first
      expect(user).to be_nil
    end
  end

  describe '.with_users' do
    it 'returns an array of class members paired with their User instance' do
      lesson = create(:lesson)

      pair = described_class.all.with_users.first
      user = described_class.all.users.first

      expect(pair).to eq([lesson, user])
    end

    it 'returns nil values for members where no profile account exists' do
      lesson = create(:lesson, user_id: SecureRandom.uuid)

      pair = described_class.all.with_users.first
      expect(pair).to eq([lesson, nil])
    end

    it 'ignores members not included in the current scope' do
      create(:lesson)

      pair = described_class.none.with_users.first
      expect(pair).to be_nil
    end
  end

  describe '#with_user' do
    it 'returns the class member paired with their User instance' do
      lesson = create(:lesson)

      pair = lesson.with_user
      user = described_class.all.users.first

      expect(pair).to eq([lesson, user])
    end

    it 'returns a nil value if the member has no profile account' do
      lesson = create(:lesson, user_id: SecureRandom.uuid)

      pair = lesson.with_user
      expect(pair).to eq([lesson, nil])
    end
  end
end
