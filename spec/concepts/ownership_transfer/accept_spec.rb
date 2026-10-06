# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OwnershipTransfer::Accept, type: :unit do
  let(:school) { create(:verified_school) }
  let(:owner) { create(:owner, school:) }
  let(:nominee) { create(:teacher, school:) }

  let!(:ownership_transfer) do
    create(
      :ownership_transfer,
      school:,
      nominated_user_id: nominee.id,
      requested_by_user_id: owner.id,
      email_address: nominee.email
    )
  end

  it 'returns a successful response with the completed transfer' do
    described_class.call(ownership_transfer:)

    expect(ownership_transfer.reload.status).to eq('completed')
  end

  it 'gives the nominee the owner role' do
    described_class.call(ownership_transfer:)

    expect(Role.owner.find_by(user_id: nominee.id, school:)).not_to be_nil
  end

  it 'archives the previous owner role' do
    described_class.call(ownership_transfer:)

    expect(Role.owner.find_by(user_id: owner.id, school:)).to be_nil
    expect(Role.unscoped.owner.find_by(user_id: owner.id, school:).archived_at).to be_present
  end

  it 'leaves the previous owner any teacher role they held' do
    create(:teacher_role, user_id: owner.id, school:)

    described_class.call(ownership_transfer:)

    expect(Role.teacher.find_by(user_id: owner.id, school:)).not_to be_nil
  end

  context 'when the nominee previously held an archived owner role for the school' do
    before { create(:owner_role, user_id: nominee.id, school:, archived_at: Time.zone.now) }

    it 'unarchives it instead of creating a second owner role' do
      described_class.call(ownership_transfer:)

      expect(Role.unscoped.owner.where(user_id: nominee.id, school:).count).to eq(1)
      expect(Role.owner.find_by(user_id: nominee.id, school:)).not_to be_nil
    end
  end

  context 'when an unexpected error occurs' do
    before do
      allow(described_class).to receive(:promote_nominee).and_raise(StandardError, 'some error')
    end

    it 'rolls back the whole operation, leaving the transfer pending and the previous owner in place' do
      begin
        described_class.call(ownership_transfer:)
      rescue StandardError
        # Expected
      end

      expect(ownership_transfer.reload.status).to eq('pending')
      expect(Role.owner.find_by(user_id: owner.id, school:)).not_to be_nil
    end
  end
end
