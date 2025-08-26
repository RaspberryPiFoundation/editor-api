# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOwner::List, type: :unit do
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }
  let(:owner_ids) { [owner.id] }

  before do
    stub_user_info_api_for(owner)
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:)
    expect(response.success?).to be(true)
  end

  it 'returns the school owners in the operation response' do
    response = described_class.call(school:)
    expect(response[:school_owners].first).to be_a(User)
  end

  context 'when an error occurs' do
    let(:response) { described_class.call(school:, owner_ids:) }

    let(:error_message) { 'Error listing school owners: some error' }

    before do
      allow(User).to receive(:from_userinfo).with(ids: owner_ids).and_raise(StandardError.new('some error'))
      allow(Sentry).to receive(:capture_exception)
    end

    it 'captures the exception and returns an error response' do
      # Call the method to ensure the error is raised and captured
      response
      expect(Sentry).to have_received(:capture_exception).with(instance_of(StandardError))
      expect(response[:school_owners]).to be_nil
      expect(response[:error]).to eq(error_message)
    end
  end
end
