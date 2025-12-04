# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  subject(:user) { build(:user) }

  let(:school) { create(:school) }
  let(:organisation_id) { school.id }

  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:email) }

  describe '.from_userinfo' do
    subject(:users) { described_class.from_userinfo(ids:) }

    let(:owner) { create(:owner, school:, name: 'School Owner', email: 'school-owner@example.com') }
    let(:ids) { [owner.id] }
    let(:user) { users.first }

    before do
      stub_user_info_api_for(owner)
    end

    it 'returns an Array' do
      expect(users).to be_an Array
    end

    it 'returns an array of instances of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq ids.first
    end

    it 'returns a user with the correct name' do
      expect(user.name).to eq 'School Owner'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'school-owner@example.com'
    end
  end

  describe '.from_token' do
    subject(:user) { described_class.from_token(token: UserProfileMock::TOKEN) }

    context 'when logged into a full account' do
      let(:owner) { create(:owner, school:, name: 'School Owner', email: 'school-owner@example.com') }

      before do
        authenticated_in_hydra_as(owner)
      end

      it 'returns an instance of the described class' do
        expect(user).to be_a described_class
      end

      it 'returns a user with the correct ID' do
        expect(user.id).to eq owner.id
      end

      it 'returns a user with the correct name' do
        expect(user.name).to eq owner.name
      end

      it 'returns a user with the correct email' do
        expect(user.email).to eq 'school-owner@example.com'
      end

      it 'returns a user without a username' do
        expect(user.username).to be_nil
      end
    end

    context 'when logged into a student account' do
      let(:student) { create(:student, school:, name: 'School Student') }

      before do
        authenticated_in_hydra_as(student, :student)
      end

      it 'returns an instance of the described class' do
        expect(user).to be_a described_class
      end

      it 'returns a user with the correct ID' do
        expect(user.id).to eq student.id
      end

      it 'returns a user with the correct name' do
        expect(user.name).to eq student.name
      end

      it 'returns a user with the correct username' do
        expect(user.username).to eq student.username
      end

      it 'returns a user without an email' do
        expect(user.email).to be_nil
      end
    end

    context 'when the access token is invalid' do
      before do
        allow(Sentry).to receive(:capture_exception)
        stub_request(:get, "#{HydraPublicApiClient::API_URL}/userinfo").to_return(status: 401)
      end

      it 'returns nil' do
        expect(user).to be_nil
      end

      it 'reports the Faraday::UnauthorizedError exception to Sentry' do
        user
        expect(Sentry).to have_received(:capture_exception).with(instance_of(Faraday::UnauthorizedError))
      end
    end
  end

  describe '.from_omniauth' do
    subject(:auth_subject) { described_class.from_omniauth(auth) }

    let(:id) { 'f80ba5b2-2eee-457d-9f75-872b5c09be84' }
    let(:info_without_organisations) do
      {
        'id' => id,
        'email' => 'john.doe@example.com',
        'name' => 'John Doe',
        'roles' => 'school-student'
      }
    end
    let(:info) { info_without_organisations }
    let(:user) { described_class.new(info) }
    let(:credentials) { { token: 'token' } }

    let(:auth) do
      OmniAuth::AuthHash.new(
        {
          provider: 'rpi',
          uid: id,
          extra: {
            raw_info: info
          },
          credentials:
        }
      )
    end

    it 'returns a User object' do
      expect(auth_subject).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(auth_subject.id).to eq id
    end

    it 'returns a user with the correct name' do
      expect(auth_subject.name).to eq 'John Doe'
    end

    it 'returns a user with the access token supplied in credentials' do
      expect(auth_subject.token).to eq 'token'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'john.doe@example.com'
    end

    context 'with unusual keys in info' do
      let(:info) { { foo: :bar, flibble: :woo } }

      it { is_expected.to be_a described_class }
    end

    context 'with no info' do
      let(:info) { nil }

      it { is_expected.to be_a described_class }
    end

    context 'with no auth set' do
      let(:auth) { nil }

      it { is_expected.to be_nil }
    end

    context 'with no credentials set' do
      let(:credentials) { nil }

      it 'returns a user with no token' do
        expect(auth_subject.token).to be_nil
      end
    end
  end

  describe '#school_owner?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the owner role for this school' do
      create(:owner_role, school:, user_id: user.id)
      expect(user).to be_school_owner(school)
    end

    it 'returns false when the user does not have the owner role for this school' do
      create(:teacher_role, school:, user_id: user.id)
      expect(user).not_to be_school_owner(school)
    end
  end

  describe '#school_teacher?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the teacher role for this school' do
      create(:teacher_role, school:, user_id: user.id)
      expect(user).to be_school_teacher(school)
    end

    it 'returns false when the user does not have the teacher role for this school' do
      create(:owner_role, school:, user_id: user.id)
      expect(user).not_to be_school_teacher(school)
    end
  end

  describe '#school_student?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the student role for this school' do
      create(:student_role, school:, user_id: user.id)
      expect(user).to be_school_student(school)
    end

    it 'returns false when the user does not have the student role for this school' do
      create(:owner_role, school:, user_id: user.id)
      expect(user).not_to be_school_student(school)
    end
  end

  describe '#student?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has a student role' do
      create(:student_role, school:, user_id: user.id)
      expect(user).to be_student
    end

    it 'returns false when the user does not have a student role' do
      create(:owner_role, school:, user_id: user.id)
      expect(user).not_to be_student
    end
  end

  describe '#parsed_roles' do
    it 'returns array of role names when roles is set to comma-separated string' do
      user = build(:user, roles: 'role-1,role-2')
      expect(user.parsed_roles).to eq(%w[role-1 role-2])
    end

    it 'strips leading & trailing spaces from role names' do
      user = build(:user, roles: ' role-1 , role-2 ')
      expect(user.parsed_roles).to eq(%w[role-1 role-2])
    end

    it 'returns empty array when roles is set to empty string' do
      user = build(:user, roles: '')
      expect(user.parsed_roles).to eq([])
    end

    it 'returns empty array when roles is set to nil' do
      user = build(:user, roles: nil)
      expect(user.parsed_roles).to eq([])
    end
  end

  describe '#admin?' do
    it 'returns true if the user has the editor-admin role in Hydra' do
      user = build(:user, roles: 'editor-admin')
      expect(user).to be_admin
    end

    it 'returns false if the user does not have the editor-admin role in Hydra' do
      user = build(:user, roles: 'another-editor-admin')
      expect(user).not_to be_admin
    end
  end

  describe '#experience_cs_admin?' do
    it 'returns true if the user has the experience-cs-admin role in Hydra' do
      user = build(:experience_cs_admin_user)
      expect(user).to be_experience_cs_admin
    end

    it 'returns false if the user does not have the experience-cs-admin role in Hydra' do
      user = build(:user, roles: 'another-admin')
      expect(user).not_to be_experience_cs_admin
    end
  end

  describe '#school_roles' do
    subject(:user) { build(:user) }

    let(:school) { create(:school) }

    context 'when the user has no roles' do
      it 'returns an empty array if the user has no role in this school' do
        expect(user.school_roles(school)).to be_empty
      end
    end

    context 'when the user has an organisation and roles' do
      before do
        create(:role, school:, user_id: user.id, role: 'owner')
        create(:role, school:, user_id: user.id, role: 'teacher')
      end

      it 'returns an array of the roles the user has at the school' do
        expect(user.school_roles(school)).to match_array(%w[owner teacher])
      end
    end
  end

  describe '.where' do
    subject(:user) { described_class.where(id: owner.id).first }

    let(:owner) { create(:owner, school:, name: 'School Owner', email: 'school-owner@example.com') }

    before do
      stub_user_info_api_for(owner)
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq owner.id
    end

    it 'returns a user with the correct name' do
      expect(user.name).to eq 'School Owner'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'school-owner@example.com'
    end
  end

  describe '#schools' do
    it 'includes schools where the user has the owner role' do
      create(:owner_role, school:, user_id: user.id)
      expect(user.schools).to eq([school])
    end

    it 'includes schools where the user has the teacher role' do
      create(:teacher_role, school:, user_id: user.id)
      expect(user.schools).to eq([school])
    end

    it 'includes schools where the user has the student role' do
      create(:student_role, school:, user_id: user.id)
      expect(user.schools).to eq([school])
    end

    it 'does not include schools where the user has no role' do
      expect(user.schools).to be_empty
    end

    it 'only includes a school once even if the user has multiple roles' do
      create(:owner_role, school:, user_id: user.id)
      create(:teacher_role, school:, user_id: user.id)
      expect(user.schools).to eq([school])
    end
  end
end
