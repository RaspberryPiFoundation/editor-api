# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOwnershipMailer do
  describe 'request_ownership_transfer' do
    subject(:email) { described_class.with(ownership_transfer:).request_ownership_transfer }

    let(:school) { create(:verified_school) }
    let(:nominee) { create(:teacher, school:) }
    let(:requested_owner) { create(:owner, school:) }
    let(:ownership_transfer) do
      create(:ownership_transfer, school:, nominated_user_id: nominee.id, requested_by_user_id: requested_owner.id)
    end

    before do
      stub_user_info_api_fetch_by_ids(
        user_ids: [nominee.id, requested_owner.id],
        users: [{ id: nominee.id, name: nominee.name }, { id: requested_owner.id, name: requested_owner.name }]
      )
      allow(ENV).to receive(:fetch).with('EDITOR_PUBLIC_URL').and_return('http://example.com')
    end

    it 'includes the nominee name in the body' do
      expect(email.body.to_s).to include(nominee.name)
    end

    it 'includes the name of requested owner in the body' do
      expect(email.body.to_s).to include(requested_owner.name)
    end

    it 'includes the school name in the body' do
      expect(email.body.to_s).to include(ownership_transfer.school.name)
    end

    it 'includes a link to respond to the ownership transfer request in the body' do
      expect(email.body.to_s).to include('http://example.com/school')
    end

    it 'includes the school name in the subject' do
      expect(email.subject).to include(ownership_transfer.school.name)
    end
  end
end
