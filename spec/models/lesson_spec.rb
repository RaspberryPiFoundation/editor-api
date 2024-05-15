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

    it 'optionally belongs to a parent' do
      lesson = create(:lesson, parent: build(:lesson))
      expect(lesson.parent).to be_a(described_class)
    end

    it 'has many copies' do
      lesson = create(:lesson, copies: [build(:lesson), build(:lesson)])
      expect(lesson.copies.size).to eq(2)
    end

    it 'has many projects' do
      user_id = SecureRandom.uuid
      lesson = create(:lesson, user_id:, projects: [build(:project, user_id:)])
      expect(lesson.projects.size).to eq(1)
    end
  end

  describe 'callbacks' do
    it 'cannot be destroyed and should be archived instead' do
      lesson = create(:lesson)
      expect { lesson.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
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
        lesson.update!(school: create(:school))
      end

      it 'requires that the user that has the school-owner or school-teacher role for the school' do
        stub_user_info_api_for_student
        lesson.user_id = '22222222-2222-2222-2222-222222222222' # school-student
        expect(lesson).to be_invalid
      end
    end

    context 'when the lesson has a school_class' do
      before do
        lesson.update!(school_class: create(:school_class))
      end

      it 'requires that the user that is the school-teacher for the school_class' do
        lesson.user_id = '00000000-0000-0000-0000-000000000000' # school-owner
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

  describe '.archived' do
    let!(:archived_lesson) { create(:lesson, archived_at: Time.now.utc) }
    let!(:unarchived_lesson) { create(:lesson) }

    it 'includes archived lessons' do
      expect(described_class.archived).to include(archived_lesson)
    end

    it 'excludes unarchived lessons' do
      expect(described_class.archived).not_to include(unarchived_lesson)
    end
  end

  describe '.unarchived' do
    let!(:archived_lesson) { create(:lesson, archived_at: Time.now.utc) }
    let!(:unarchived_lesson) { create(:lesson) }

    it 'includes unarchived lessons' do
      expect(described_class.unarchived).to include(unarchived_lesson)
    end

    it 'excludes archived lessons' do
      expect(described_class.unarchived).not_to include(archived_lesson)
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

  describe '#archive!' do
    let(:lesson) { build(:lesson) }

    it 'archives the lesson' do
      lesson.archive!
      expect(lesson.archived?).to be(true)
    end

    it 'sets archived_at' do
      lesson.archive!
      expect(lesson.archived_at).to be_present
    end

    it 'does not set archived_at if it was already set' do
      lesson.update!(archived_at: 1.day.ago)

      lesson.archive!
      expect(lesson.archived_at).to be < 23.hours.ago
    end

    it 'saves the record' do
      lesson.archive!
      expect(lesson).to be_persisted
    end

    it 'is infallible to other validation errors' do
      lesson.save!
      lesson.name = ' '
      lesson.save!(validate: false)

      lesson.archive!
      expect(lesson.archived?).to be(true)
    end
  end

  describe '#unarchive!' do
    let(:lesson) { build(:lesson, archived_at: Time.now.utc) }

    it 'unarchives the lesson' do
      lesson.unarchive!
      expect(lesson.archived?).to be(false)
    end

    it 'clears archived_at' do
      lesson.unarchive!
      expect(lesson.archived_at).to be_nil
    end

    it 'saves the record' do
      lesson.unarchive!
      expect(lesson).to be_persisted
    end

    it 'is infallible to other validation errors' do
      lesson.archive!
      lesson.name = ' '
      lesson.save!(validate: false)

      lesson.unarchive!
      expect(lesson.archived?).to be(false)
    end
  end
end
