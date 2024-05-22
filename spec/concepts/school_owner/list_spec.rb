# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOwner::List, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:owner_id) { SecureRandom.uuid }

  before do
    stub_profile_api_list_school_owners(user_id: owner_id)
    stub_user_info_api_for_owner(owner_id:, school_id: School::ID)
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, token:)
    expect(response.success?).to be(true)
  end

  it 'makes a profile API call' do
    described_class.call(school:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:list_school_owners).with(token:, organisation_id: school.id)
  end

  it 'returns the school owners in the operation response' do
    response = described_class.call(school:, token:)
    expect(response[:school_owners].first).to be_a(User)
  end

  context 'when listing fails' do
    before do
      allow(ProfileApiClient).to receive(:list_school_owners).and_raise('Some API error')
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, token:)
      expect(response[:error]).to match(/Some API error/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
