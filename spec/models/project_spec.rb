# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  let(:school) { create(:school) }

  describe 'associations' do
    it { is_expected.to belong_to(:school).optional(true) }
    it { is_expected.to belong_to(:lesson).optional(true) }
    it { is_expected.to belong_to(:parent).optional(true) }
    it { is_expected.to have_many(:remixes).dependent(:nullify) }
    it { is_expected.to have_many(:components) }
    it { is_expected.to have_many(:project_errors).dependent(:nullify) }
    it { is_expected.to have_many_attached(:images) }

    it 'purges attached images' do
      expect(described_class.reflect_on_attachment(:images).options[:dependent]).to eq(:purge_later)
    end
  end

  describe 'validations' do
    let(:project) { create(:project) }
    let(:identifier) { project.identifier }

    it 'has a valid default factory' do
      expect(build(:project)).to be_valid
    end

    it 'can save the default factory' do
      expect { build(:project).save! }.not_to raise_error
    end

    it 'is invalid if no user or locale' do
      invalid_project = build(:project, locale: nil, user_id: nil)
      expect(invalid_project).to be_invalid
    end

    it 'is valid if user but no locale' do
      valid_project = build(:project, locale: nil)
      expect(valid_project).to be_valid
    end

    context 'with same identifier and same user as existing project' do
      let(:user_id) { project.user_id }

      it 'is invalid if identifier in use by same user in the same locale' do
        new_project = build(:project, identifier:, user_id:, locale: project.locale)
        expect(new_project).to be_invalid
      end

      it 'is valid if identifier only in use by the user in the another locale' do
        new_project = build(:project, identifier:, user_id:, locale: 'another_locale')
        expect(new_project).to be_valid
      end
    end

    context 'with same identifier but different user as existing project' do
      let(:user_id) { 'another_user' }

      it 'is invalid if identifier in use by another user in same locale' do
        new_project = build(:project, identifier:, user_id:, locale: project.locale)
        expect(new_project).to be_invalid
      end

      it 'is invalid if identifier in use in another locale by another user' do
        new_project = build(:project, identifier:, user_id:, locale: 'another_locale')
        expect(new_project).to be_invalid
      end
    end

    context 'when the project has a school' do
      before do
        project.update!(school: create(:school))
      end

      it 'requires that the user that has a role within the school' do
        project.user_id = SecureRandom.uuid
        expect(project).to be_invalid
      end
    end

    context 'when the project has a lesson' do
      let(:school) { create(:school) }
      let(:teacher) { create(:teacher, school:) }
      let(:student) { create(:student, school:) }
      let(:school_class) { create(:school_class, school:, teacher_id: teacher.id) }

      before do
        lesson = create(:lesson, school:, school_class:, user_id: teacher.id)

        project.update!(lesson:, school:, user_id: lesson.user_id, identifier: 'something')
      end

      it 'fails if the user is the owner of the lesson' do
        project.user_id = SecureRandom.uuid
        expect(project).to be_invalid
      end

      it 'succeeds if the user is the owner of the lesson' do
        expect(project).to be_valid
      end

      it 'fails if the user is not a member of the lesson' do
        create(:class_member, school_class:, student_id: teacher.id)

        project.user_id = student.id
        expect(project).to be_invalid
      end

      it 'suceeds if the user is a member of the lesson' do
        create(:class_member, school_class:, student_id: student.id)

        project.user_id = student.id
        expect(project).to be_invalid
      end
    end
  end

  describe 'check_unique_not_null' do
    let(:saved_project) { create(:project) }

    it 'generates an identifier if nil' do
      unsaved_project = build(:project, identifier: nil)
      expect { unsaved_project.valid? }.to change { unsaved_project.identifier.nil? }.from(true).to(false)
    end
  end

  describe '.users' do
    it 'returns User instances for the current scope' do
      student = create(:student, school:, name: 'School Student')
      stub_user_info_api_for(student)
      create(:project, user_id: student.id)

      user = described_class.all.users.first
      expect(user.name).to eq('School Student')
    end

    it 'ignores members where no profile account exists' do
      user_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id:)
      create(:project, user_id:)

      user = described_class.all.users.first
      expect(user).to be_nil
    end

    it 'ignores members not included in the current scope' do
      create(:project)

      user = described_class.none.users.first
      expect(user).to be_nil
    end
  end

  describe '.with_users' do
    # rubocop:disable RSpec/ExampleLength
    it 'returns an array of class members paired with their User instance' do
      student = create(:student, school:)
      stub_user_info_api_for(student)
      project = create(:project, user_id: student.id)

      pair = described_class.all.with_users.first
      user = described_class.all.users.first

      expect(pair).to eq([project, user])
    end
    # rubocop:enable RSpec/ExampleLength

    it 'returns nil values for members where no profile account exists' do
      user_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id:)
      project = create(:project, user_id:)

      pair = described_class.all.with_users.first
      expect(pair).to eq([project, nil])
    end

    it 'ignores members not included in the current scope' do
      create(:project)

      pair = described_class.none.with_users.first
      expect(pair).to be_nil
    end
  end

  describe '#with_user' do
    # rubocop:disable RSpec/ExampleLength
    it 'returns the class member paired with their User instance' do
      student = create(:student, school:)
      stub_user_info_api_for(student)
      project = create(:project, user_id: student.id)

      pair = project.with_user
      user = described_class.all.users.first

      expect(pair).to eq([project, user])
    end
    # rubocop:enable RSpec/ExampleLength

    it 'returns a nil value if the member has no profile account' do
      user_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id:)
      project = create(:project, user_id:)

      pair = project.with_user
      expect(pair).to eq([project, nil])
    end
  end
end
