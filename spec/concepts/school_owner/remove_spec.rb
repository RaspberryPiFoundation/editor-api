# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOwner::Remove, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:owner_id) { SecureRandom.uuid }

  before do
    stub_profile_api_remove_school_owner
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, owner_id:, token:)
    expect(response.success?).to be(true)
  end

  it 'makes a profile API call' do
    described_class.call(school:, owner_id:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:remove_school_owner)
      .with(token:, owner_id:, organisation_id: school.id)
  end

  context 'when removal fails' do
    before do
      allow(ProfileApiClient).to receive(:remove_school_owner).and_raise('Some API error')
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, owner_id:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, owner_id:, token:)
      expect(response[:error]).to match(/Some API error/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, owner_id:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
