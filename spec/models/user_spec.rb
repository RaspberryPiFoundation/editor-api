# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  subject(:user) { build(:user) }

  let(:school) { create(:school) }
  let(:organisation_id) { school.id }

  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:email) }
  it { is_expected.to respond_to(:organisations) }
  it { is_expected.to respond_to(:organisation_ids) }

  shared_examples 'role_check' do |role|
    let(:organisations) { {} }
    let(:user) { build(:user, organisations:) }

    it { is_expected.to be_falsey }

    context 'with a blank roles entry' do
      let(:organisations) { { organisation_id => ' ' } }

      it { is_expected.to be_falsey }
    end

    context 'with an unrelated role given' do
      let(:organisations) { { organisation_id => 'foo' } }

      it { is_expected.to be_falsey }
    end

    context "with a #{role} role given" do
      let(:organisations) { { organisation_id => role } }

      it { is_expected.to be_truthy }

      context 'with unrelated roles too' do
        let(:organisations) { { organisation_id => "foo,bar,#{role},quux" } }

        it { is_expected.to be_truthy }
      end

      context 'with weird extra whitespace in role' do
        let(:organisations) { { organisation_id => " #{role} " } }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.from_userinfo' do
    subject(:users) { described_class.from_userinfo(ids:) }

    let(:ids) { [SecureRandom.uuid] }
    let(:user) { users.first }

    before do
      stub_user_info_api_for_owner(owner_id: ids.first, school_id: school.id)
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

    it 'returns a user with the correct organisations' do
      expect(user.organisations).to eq(organisation_id => 'school-owner')
    end

    context 'when no organisations are returned' do
      let(:ids) { [SecureRandom.uuid] }

      it 'returns a user with the correct organisations' do
        stub_user_info_api_for_student_without_organisations(student_id: ids.first)

        expect(user.organisations).to eq('12345678-1234-1234-1234-123456789abc' => 'school-student')
      end
    end
  end

  describe '.from_token' do
    subject(:user) { described_class.from_token(token: UserProfileMock::TOKEN) }

    let(:owner_id) { SecureRandom.uuid }

    before do
      authenticate_as_school_owner(owner_id:, school_id: organisation_id)
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq owner_id
    end

    it 'returns a user with the correct name' do
      expect(user.name).to eq 'School Owner'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'school-owner@example.com'
    end

    it 'returns a user with the correct organisations' do
      expect(user.organisations).to eq(organisation_id => 'school-owner')
    end

    context 'when no organisations are returned' do
      before do
        authenticate_as_school_student_without_organisations
      end

      it 'returns a user with the correct organisations' do
        expect(user.organisations).to eq('12345678-1234-1234-1234-123456789abc' => 'school-student')
      end
    end

    context 'when BYPASS_AUTH is true' do
      around do |example|
        ClimateControl.modify(BYPASS_AUTH: 'true') do
          example.run
        end
      end

      it 'does not call the API' do
        user
        expect(WebMock).not_to have_requested(:get, /.*/)
      end

      it 'returns a stubbed user' do
        expect(user.name).to eq('School Owner')
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

    let(:auth) do
      OmniAuth::AuthHash.new(
        {
          provider: 'rpi',
          uid: id,
          extra: {
            raw_info: info
          }
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

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'john.doe@example.com'
    end

    it 'returns a user with the correct organisations' do
      expect(auth_subject.organisations).to eq('12345678-1234-1234-1234-123456789abc' => 'school-student')
    end

    context 'when info includes organisations' do
      let(:info) { info_without_organisations.merge!('organisations' => { 'c78ab987-5fa8-482e-a9cf-a5e93513349b' => 'school-student' }) }

      it 'returns a user with the supplied organisations' do
        expect(auth_subject.organisations).to eq('c78ab987-5fa8-482e-a9cf-a5e93513349b' => 'school-student')
      end
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
  end

  describe '#school_owner?' do
    subject { user.school_owner?(organisation_id:) }

    include_examples 'role_check', 'school-owner'
  end

  describe '#school_teacher?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the teacher role for this school' do
      create(:teacher_role, school:, user_id: user.id)
      expect(user).to be_school_teacher(organisation_id: school.id)
    end

    it 'returns false when the user does not have the teacher role for this school' do
      create(:owner_role, school:, user_id: user.id)
      expect(user).not_to be_school_teacher(organisation_id: school.id)
    end
  end

  describe '#school_student?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the student role for this school' do
      create(:student_role, school:, user_id: user.id)
      expect(user).to be_school_student(organisation_id: school.id)
    end

    it 'returns false when the user does not have the student role for this school' do
      create(:owner_role, school:, user_id: user.id)
      expect(user).not_to be_school_student(organisation_id: school.id)
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

    it 'returns false if roles are empty in Hydra' do
      user = build(:user, roles: '')
      expect(user).not_to be_admin
    end

    it 'returns false if roles are nil in Hydra' do
      user = build(:user, roles: nil)
      expect(user).not_to be_admin
    end
  end

  describe '.where' do
    subject(:user) { described_class.where(id: owner_id).first }

    let(:owner_id) { SecureRandom.uuid }

    before do
      stub_user_info_api_for_owner(owner_id:, school_id: school.id)
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq owner_id
    end

    it 'returns a user with the correct name' do
      expect(user.name).to eq 'School Owner'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'school-owner@example.com'
    end

    context 'when BYPASS_AUTH is true' do
      around do |example|
        ClimateControl.modify(BYPASS_AUTH: 'true') do
          example.run
        end
      end

      let(:owner_id) { '00000000-0000-0000-0000-000000000000' }

      it 'does not call the API' do
        user
        expect(WebMock).not_to have_requested(:get, /.*/)
      end

      it 'returns a stubbed user' do
        expect(user.name).to eq('School Owner')
      end
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
