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

  describe '#from_token' do
    subject(:user) { described_class.from_token(token: UserProfileMock::TOKEN) }

    before do
      stub_hydra_public_api
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

  describe '#from_omniauth' do
    subject(:auth_subject) { described_class.from_omniauth(auth) }

    let(:user) { build(:user) }
    let(:info) { user.serializable_hash(except: :id) }

    let(:auth) do
      OmniAuth::AuthHash.new(
        {
          provider: 'rpi',
          uid: user.id,
          extra: {
            raw_info: info
          }
        }
      )
    end

    it 'returns a User object' do
      expect(auth_subject).to be_a described_class
    end

    it 'sets the user attributes correctly' do
      expect(auth_subject.serializable_hash).to eq user.serializable_hash
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
    subject { user.school_teacher?(organisation_id:) }

    include_examples 'role_check', 'school-teacher'
  end

  describe '#school_student?' do
    subject { user.school_student?(organisation_id:) }

    include_examples 'role_check', 'school-student'
  end

  describe '#where' do
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
