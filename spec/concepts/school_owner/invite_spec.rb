# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOwner::Invite, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:owner_index) { user_index_by_role('school-owner') }
  let(:owner_id) { user_id_by_index(owner_index) }

  let(:school_owner_params) do
    { email_address: 'owner-to-invite@example.com' }
  end

  before do
    stub_profile_api_invite_school_owner
  end

  it 'makes a profile API call' do
    described_class.call(school:, school_owner_params:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:invite_school_owner)
      .with(token:, email_address: 'owner-to-invite@example.com', organisation_id: school.id)
  end

  context 'when creation fails' do
    let(:school_owner_params) do
      { email_address: 'invalid' }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not make a profile API request' do
      described_class.call(school:, school_owner_params:, token:)
      expect(ProfileApiClient).not_to have_received(:invite_school_owner)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_owner_params:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_owner_params:, token:)
      expect(response[:error]).to match(/email address 'invalid' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_owner_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end