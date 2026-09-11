# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOwnershipMailer do
  describe 'request_ownership_transfer' do
    subject(:email) { described_class.with(ownership_transfer:).request_ownership_transfer }

    let(:ownership_transfer) { create(:ownership_transfer) }

    before do
      allow(ENV).to receive(:fetch).with('EDITOR_PUBLIC_URL').and_return('http://example.com')
    end

    it 'includes the school name in the body' do
      expect(email.body.to_s).to include(ownership_transfer.school.name)
    end

    it 'includes a link to respond to the ownership transfer request in the body' do
      allow(ownership_transfer).to receive(:generate_token_for).and_return('token-id')

      expect(email.body.to_s).to include('http://example.com/en/ownership_transfers/token-id')
    end

    it 'includes the school name in the subject' do
      expect(email.subject).to include(ownership_transfer.school.name)
    end
  end
end
