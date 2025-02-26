# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, versioning: true do
  let(:school) { create(:school) }

  describe 'associations' do
    it { is_expected.to belong_to(:school).optional(true) }
    it { is_expected.to belong_to(:lesson).optional(true) }
    it { is_expected.to belong_to(:parent).optional(true) }
    it { is_expected.to have_many(:remixes).dependent(:nullify) }
    it { is_expected.to have_many(:components) }
    it { is_expected.to have_many(:project_errors).dependent(:nullify) }
    it { is_expected.to have_many_attached(:images) }
    it { is_expected.to have_many_attached(:videos) }
    it { is_expected.to have_many_attached(:audio) }
    it { is_expected.to have_one(:school_project).dependent(:destroy) }

    it 'purges attached images' do
      expect(described_class.reflect_on_attachment(:images).options[:dependent]).to eq(:purge_later)
    end

    it 'purges attached videos' do
      expect(described_class.reflect_on_attachment(:videos).options[:dependent]).to eq(:purge_later)
    end

    it 'purges attached audio' do
      expect(described_class.reflect_on_attachment(:audio).options[:dependent]).to eq(:purge_later)
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

    it 'is invalid if school_id but no school project' do
      invalid_project = build(:project, school_id: SecureRandom.uuid)
      expect(invalid_project).to be_invalid
    end

    it 'is invalid if school_id and school project with different school_id' do
      invalid_project = build(:project, school_id: SecureRandom.uuid, school_project: build(:school_project, school_id: SecureRandom.uuid))
      expect(invalid_project).to be_invalid
    end

    it 'is valid if school_id and school project with matching school_id' do
      school_id = SecureRandom.uuid
      valid_project = build(:project, school_id:, school_project: build(:school_project, school_id:))
      expect(valid_project).to be_valid
    end

    it 'is invalid if a school project with lesson and class but user is not class member' do
      school = create(:school)
      teacher = create(:teacher, school:)
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])
      lesson = create(:lesson, school:, school_class:, user_id: teacher.id)
      invalid_project = build(:project, school:, lesson:, user_id: SecureRandom.uuid)

      expect(invalid_project).to be_invalid
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
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }

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
        create(:class_student, school_class:, student_id: teacher.id)

        project.user_id = student.id
        expect(project).to be_invalid
      end

      it 'suceeds if the user is a member of the lesson' do
        create(:class_student, school_class:, student_id: student.id)

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

  describe 'create_school_project_if_needed' do
    let(:teacher) { create(:teacher, school:) }
    let(:teacher_project) { create(:project, school_id: school.id, user_id: teacher.id) }
    let(:project) { create(:project) }

    it 'creates a school project if the project belongs to a school' do
      expect(teacher_project.school_project).to be_present
    end

    it 'gives the school project the same school_id as the project' do
      expect(teacher_project.school_project.school_id).to eq(school.id)
    end

    it 'does not create a school project if the project does not belong to a school' do
      expect(project.school_project).to be_nil
    end
  end

  describe '.users' do
    let(:student) { create(:student, school:, name: 'School Student') }
    let(:teacher) { create(:teacher, school:) }

    let(:student_attributes) do
      [{ id: student.id, name: student.name, username: student.username }]
    end

    before do
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'returns User instances for the current scope' do
      create(:project, user_id: student.id, school_id: school.id)
      user = described_class.all.users(teacher).first
      expect(user.name).to eq('School Student')
    end

    it 'ignores members where no profile account exists' do
      user_id = SecureRandom.uuid
      create(:project, user_id:)

      user = described_class.all.users(teacher).first
      expect(user).to be_nil
    end

    it 'ignores members not included in the current scope' do
      create(:project)

      user = described_class.none.users(teacher).first
      expect(user).to be_nil
    end
  end

  describe '.with_users' do
    let(:student) { create(:student, school:) }
    let(:teacher) { create(:teacher, school:) }

    let(:student_attributes) do
      [{ id: student.id, name: student.name, username: student.username }]
    end

    before do
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'returns an array of class members paired with their User instance' do
      project = create(:project, user_id: student.id)

      pair = described_class.all.with_users(teacher).first
      user = described_class.all.users(teacher).first

      expect(pair).to eq([project, user])
    end

    it 'returns nil values for members where no profile account exists' do
      user_id = SecureRandom.uuid
      project = create(:project, user_id:)

      pair = described_class.all.with_users(teacher).first
      expect(pair).to eq([project, nil])
    end

    it 'ignores members not included in the current scope' do
      create(:project)

      pair = described_class.none.with_users(teacher).first
      expect(pair).to be_nil
    end
  end

  describe '#with_user' do
    let(:student) { create(:student, school:) }
    let(:teacher) { create(:teacher, school:) }

    let(:student_attributes) do
      [{ id: student.id, name: student.name, username: student.username }]
    end

    before do
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'returns the class member paired with their User instance' do
      project = create(:project, user_id: student.id)

      pair = project.with_user(teacher)
      user = described_class.all.users(teacher).first

      expect(pair).to eq([project, user])
    end

    it 'returns a nil value if the member has no profile account' do
      user_id = SecureRandom.uuid
      project = create(:project, user_id:)

      pair = project.with_user(teacher)
      expect(pair).to eq([project, nil])
    end
  end

  describe '#last_edited_at' do
    let(:project) { create(:project, updated_at: 1.day.ago) }
    let(:component) { create(:component, project:, updated_at: 2.days.ago) }

    it 'returns the project updated_at if most recent' do
      expect(project.last_edited_at).to eq(project.updated_at)
    end

    it 'returns the latest component updated_at if most recent' do
      latest_component = create(:component, project:, updated_at: 1.hour.ago)
      expect(project.last_edited_at).to eq(latest_component.updated_at)
    end
  end

  describe '#media' do
    let(:project) { create(:project, :with_attached_image, :with_attached_video, :with_attached_audio) }

    it 'returns all media files' do
      expect(project.media).to eq(project.images + project.videos + project.audio)
    end
  end

  describe 'auditing' do
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }

    it 'enables auditing for projects with a school_id' do
      project_with_school = create(:project, user_id: student.id, school_id: school.id)
      expect(project_with_school.versions.length).to(eq(1))
    end

    it 'does not enable auditing for projects without a school_id' do
      project_without_school = create(:project, school_id: nil)
      expect(project_without_school.versions.length).to(eq(0))
    end
  end
end
