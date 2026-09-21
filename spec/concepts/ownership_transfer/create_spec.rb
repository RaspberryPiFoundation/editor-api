# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OwnershipTransfer::Create, type: :unit do
  let(:school) { create(:verified_school) }
  let(:owner) { create(:owner, school:) }
  let(:nominee) { create(:teacher, school:) }

  before { stub_user_info_api_for(nominee) }

  it 'returns a successful response and creates the transfer' do
    response = described_class.call(school:, nominated_user_id: nominee.id, requested_by_user_id: owner.id)

    expect(response.success?).to be(true)
    expect(response[:ownership_transfer]).to have_attributes(
      school:,
      nominated_user_id: nominee.id,
      requested_by_user_id: owner.id,
      email_address: nominee.email
    )
  end

  it 'returns a failure response naming the ineligible nominee when the nominee has no role at the school' do
    response = described_class.call(school:, nominated_user_id: SecureRandom.uuid, requested_by_user_id: owner.id)

    expect(response.failure?).to be(true)
    expect(response[:error][:nominated_user_id]).to be_present
  end

  it 'returns a failure response naming the ineligible nominee when the nominee has the owner role' do
    response = described_class.call(school:, nominated_user_id: owner.id, requested_by_user_id: owner.id)

    expect(response.failure?).to be(true)
    expect(response[:error][:nominated_user_id]).to be_present
  end

  context 'when a duplicate pending transfer is created concurrently' do
    before do
      allow(OwnershipTransfer).to receive(:new).and_wrap_original do |method, *args|
        method.call(*args).tap do |ownership_transfer|
          allow(ownership_transfer).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
        end
      end
    end

    it 'returns the same friendly error a non-concurrent duplicate would get, not the raw exception' do
      response = described_class.call(school:, nominated_user_id: nominee.id, requested_by_user_id: owner.id)

      expect(response.failure?).to be(true)
      expect(response[:error][:school_id]).to include('already has a pending ownership transfer')
    end

    it 'does not report the race to Sentry, since it is an expected, handled outcome' do
      allow(Sentry).to receive(:capture_exception)

      described_class.call(school:, nominated_user_id: nominee.id, requested_by_user_id: owner.id)

      expect(Sentry).not_to have_received(:capture_exception)
    end
  end

  context 'when an unexpected error occurs' do
    before do
      allow(OwnershipTransfer).to receive(:new).and_raise(StandardError, 'boom')
      allow(Sentry).to receive(:capture_exception)
    end

    it 'reports it to Sentry and returns a generic error' do
      response = described_class.call(school:, nominated_user_id: nominee.id, requested_by_user_id: owner.id)

      expect(Sentry).to have_received(:capture_exception)
      expect(response.failure?).to be(true)
      expect(response[:error]).to include('Error creating ownership transfer')
    end
  end
end
