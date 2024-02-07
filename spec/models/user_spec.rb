# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  subject { build(:user) }

  it { is_expected.to respond_to(:id) }
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:email) }
  it { is_expected.to respond_to(:roles) }

  shared_examples 'role_check' do |role|
    let(:roles) { nil }
    let(:user) { build(:user, roles:) }

    it { is_expected.to be_falsey }

    context 'with a blank roles entry' do
      let(:roles) { ' ' }

      it { is_expected.to be_falsey }
    end

    context 'with an unrelated role given' do
      let(:roles) { 'foo' }

      it { is_expected.to be_falsey }
    end

    context "with a #{role} role given" do
      let(:roles) { role }

      it { is_expected.to be_truthy }

      context 'with unrelated roles too' do
        let(:roles) { "foo,bar,#{role},quux" }

        it { is_expected.to be_truthy }
      end

      context 'with weird extra whitespace in role' do
        let(:roles) { " #{role} " }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#from_omniauth' do
    subject(:user) { described_class.from_omniauth(token: 'my-access-token') }

    let(:stubbed_response) do
      json = File.read('spec/fixtures/users.json')
      first = JSON.parse(json)['users'][0]

      first['sub'] = first.delete('id')
      first.to_json
    end

    let(:hydra_public_url) { HydraPublicApiClient::API_URL }

    before do
      stub_request(:get, "#{hydra_public_url}/userinfo")
        .with(headers: { Authorization: 'Bearer my-access-token' })
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: stubbed_response
        )
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq 'b6301f34-b970-4d4f-8314-f877bad8b150'
    end

    it 'returns a user with the correct name' do
      expect(user.name).to eq 'Jane Doe'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'jane.doe@example.com'
    end

    it 'returns a user with the correct roles' do
      expect(user.roles).to eq 'school-teacher'
    end

    context 'when BYPASS_AUTH is true' do
      around do |example|
        ClimateControl.modify(BYPASS_AUTH: 'true') do
          example.run
        end
      end

      it 'does not call the API' do
        user
        expect(WebMock).not_to have_requested(:get, "#{hydra_public_url}/userinfo")
      end

      it 'returns a stubbed user' do
        expect(user.name).to eq('Jane Doe')
      end
    end
  end

  describe '#school_owner?' do
    subject { user.school_owner? }

    include_examples 'role_check', 'school-owner'
  end

  describe '#school_teacher?' do
    subject { user.school_teacher? }

    include_examples 'role_check', 'school-teacher'
  end

  describe '#school_student?' do
    subject { user.school_student? }

    include_examples 'role_check', 'school-student'
  end

  describe '#where' do
    subject(:user) { described_class.where(id: 'b6301f34-b970-4d4f-8314-f877bad8b150').first }

    let(:stubbed_response) { File.read('spec/fixtures/users.json') }

    let(:userinfo_api_url) { UserinfoApiClient::API_URL }
    let(:userinfo_api_key) { UserinfoApiClient::API_KEY }

    before do
      stub_request(:get, "#{userinfo_api_url}/users")
        .with(headers: { Authorization: "Bearer #{userinfo_api_key}" })
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: stubbed_response
        )
    end

    it 'returns an instance of the described class' do
      expect(user).to be_a described_class
    end

    it 'returns a user with the correct ID' do
      expect(user.id).to eq 'b6301f34-b970-4d4f-8314-f877bad8b150'
    end

    it 'returns a user with the correct name' do
      expect(user.name).to eq 'Jane Doe'
    end

    it 'returns a user with the correct email' do
      expect(user.email).to eq 'jane.doe@example.com'
    end

    context 'when BYPASS_AUTH is true' do
      around do |example|
        ClimateControl.modify(BYPASS_AUTH: 'true') do
          example.run
        end
      end

      it 'does not call the API' do
        user
        expect(WebMock).not_to have_requested(:get, "#{userinfo_api_url}/users")
      end

      it 'returns a stubbed user' do
        expect(user.name).to eq('Jane Doe')
      end
    end
  end
end
