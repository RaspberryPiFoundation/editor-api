# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  subject { build(:user) }

  let(:organisation_id) { '12345678-1234-1234-1234-123456789abc' }

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

    let(:ids) { ['00000000-0000-0000-0000-000000000000'] }
    let(:user) { users.first }

    before do
      stub_user_info_api
    end

    it 'returns an Array' do
      expect(users).to be_an Array
    end

    it 'returns an array of instances of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq '00000000-0000-0000-0000-000000000000'
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
      let(:ids) { ['33333333-3333-3333-3333-333333333333'] } # student without organisations

      it 'returns a user with the correct organisations' do
        expect(user.organisations).to eq(organisation_id => 'school-student')
      end
    end
  end

  describe '.from_token' do
    subject(:user) { described_class.from_token(token: UserProfileMock::TOKEN) }

    let(:user_index) { 0 }

    before do
      stub_hydra_public_api(user_index:)
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq '00000000-0000-0000-0000-000000000000'
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
      let(:user_index) { 3 } # student without organisations

      it 'returns a user with the correct organisations' do
        expect(user.organisations).to eq(organisation_id => 'school-student')
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
      expect(auth_subject.organisations).to eq(organisation_id => 'school-student')
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
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the owner role for this school' do
      create(:role, school:, user_id: user.id, role: 'owner')
      expect(user).to be_school_owner(organisation_id: school.id)
    end

    it 'returns false when the user does not have the owner role for this school' do
      create(:role, school:, user_id: user.id, role: 'teacher')
      expect(user).not_to be_school_owner(organisation_id: school.id)
    end
  end

  describe '#school_teacher?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the teacher role for this school' do
      create(:role, school:, user_id: user.id, role: 'teacher')
      expect(user).to be_school_teacher(organisation_id: school.id)
    end

    it 'returns false when the user does not have the teacher role for this school' do
      create(:role, school:, user_id: user.id, role: 'owner')
      expect(user).not_to be_school_teacher(organisation_id: school.id)
    end
  end

  describe '#school_student?' do
    subject(:user) { create(:user) }

    let(:school) { create(:school) }

    it 'returns true when the user has the student role for this school' do
      create(:role, school:, user_id: user.id, role: 'student')
      expect(user).to be_school_student(organisation_id: school.id)
    end

    it 'returns false when the user does not have the student role for this school' do
      create(:role, school:, user_id: user.id, role: 'owner')
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

  describe '#org_roles' do
    subject(:user) { build(:user, roles:, organisations:) }

    let(:school) { create(:school) }
    let(:organisations) { { '12345678-1234-1234-1234-123456789abc' => roles } }

    context 'when the user has no roles' do
      let(:roles) { '' }

      it 'returns an empty array if the user has no role in this school' do
        expect(user.org_roles(organisation_id: school.id)).to be_empty
      end
    end

    context 'when the user has an organisation and roles' do
      let(:roles) { 'owner,teacher' }

      it 'returns an array of the roles the user has at the school' do
        expect(user.org_roles(organisation_id: school.id)).to match_array(%w[owner teacher])
      end
    end
  end

  describe '.where' do
    subject(:user) { described_class.where(id: '00000000-0000-0000-0000-000000000000').first }

    before do
      stub_user_info_api
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq '00000000-0000-0000-0000-000000000000'
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

      it 'does not call the API' do
        user
        expect(WebMock).not_to have_requested(:get, /.*/)
      end

      it 'returns a stubbed user' do
        expect(user.name).to eq('School Owner')
      end
    end
  end
end
