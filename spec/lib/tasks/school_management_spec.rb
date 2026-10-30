# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'school_management', type: :task do
  describe ':transfer_ownership' do
    let(:task) { Rake::Task['school_management:transfer_ownership'] }
    let(:old_user_id) { SecureRandom.uuid }
    let(:new_user_id) { SecureRandom.uuid }
    let(:school) { create(:school, creator_agree_to_ux_contact: true) }

    before do
      stub_user_info_api_find_by_email(
        email: 'old_owner@example.com',
        user: { id: old_user_id, email: 'old_owner@example.com' }
      )

      stub_user_info_api_find_by_email(
        email: 'new_owner@example.com',
        user: { id: new_user_id, email: 'new_owner@example.com' }
      )

      stub_user_info_api_fetch_by_ids(
        user_ids: [new_user_id],
        users: [{ id: new_user_id, email: 'new_owner@example.com' }]
      )

      create(:owner_role, school:, user_id: old_user_id)
      create(:teacher_role, school:, user_id: old_user_id)
    end

    it "exits early if new owner doesn't exist" do
      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('not_real_owner@example.com')
        .and_return(nil)

      task.invoke('old_owner@example.com', 'not_real_owner@example.com')

      expect(school.roles.owner.pluck(:user_id)).to include(old_user_id)
    end

    it "exits early if old owner doesn't exist" do
      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('not_real_owner@example.com')
        .and_return(nil)

      task.invoke('not_real_owner@example.com', 'new_owner@example.com')

      expect(school.roles.owner.pluck(:user_id)).to include(old_user_id)
    end

    it 'exits early if new owner is already owner of a school' do
      create(:owner_role, school:, user_id: new_user_id)

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.roles.owner.pluck(:user_id)).to include(old_user_id)
    end

    it 'exits early if old owner is not the owner of a school' do
      school.roles.owner.find_by(user_id: old_user_id).destroy!

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(OwnershipTransfer.count).to eq(0)
    end

    it 'creates owner and teacher roles for the new owner' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.roles.owner.pluck(:user_id)).to eq([new_user_id])
      expect(school.roles.teacher.pluck(:user_id)).to include(new_user_id)
    end

    it 'does not error if new owner already has teacher role' do
      create(:teacher_role, school:, user_id: new_user_id)

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.roles.owner.pluck(:user_id)).to eq([new_user_id])
      expect(school.roles.teacher.pluck(:user_id)).to include(new_user_id)
    end

    it 'restores an archived teacher role for the new owner' do
      create(:teacher_role, school:, user_id: new_user_id, archived_at: 1.day.ago)

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.roles.owner.pluck(:user_id)).to eq([new_user_id])
      expect(Role.unscoped.teacher.where(school:, user_id: new_user_id).sole.archived_at).to be_nil
    end

    it 'archives the old owner role' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      old_owner_role = Role.unscoped.owner.find_by(school:, user_id: old_user_id)
      expect(old_owner_role.archived_at).to be_present
    end

    it 'records a completed ownership transfer' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.ownership_transfers.sole).to have_attributes(
        status: 'completed',
        nominated_user_id: new_user_id,
        requested_by_user_id: old_user_id,
        email_address: 'new_owner@example.com',
        admin_initiated: true
      )
    end

    it 'does not send the ownership transfer request email' do
      expect do
        task.invoke('old_owner@example.com', 'new_owner@example.com')
      end.not_to have_enqueued_mail(SchoolOwnershipMailer, :request_ownership_transfer)
    end

    it 'sends the ownership transfer completed email to the new owner' do
      expect do
        task.invoke('old_owner@example.com', 'new_owner@example.com')
      end.to have_enqueued_mail(SchoolOwnershipMailer, :complete_ownership_transfer)
    end

    it 'sends the ownership transfer completed email to the previous owner' do
      expect do
        task.invoke('old_owner@example.com', 'new_owner@example.com')
      end.to have_enqueued_mail(SchoolOwnershipMailer, :complete_ownership_transfer_previous_owner)
    end

    it 'resets creator_agree_to_ux_contact on the school' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.reload.creator_agree_to_ux_contact).to be(false)
    end

    it 'keeps the old owner as a teacher if keep parameter is true' do
      task.invoke('old_owner@example.com', 'new_owner@example.com', 'true')

      expect(school.roles.teacher.pluck(:user_id)).to include(old_user_id)
    end

    it 'removes the old owner as a teacher if keep parameter is false' do
      task.invoke('old_owner@example.com', 'new_owner@example.com', 'false')

      expect(school.roles.teacher.pluck(:user_id)).not_to include(old_user_id)
    end

    it 'removes the old owner as a teacher by default' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.roles.teacher.pluck(:user_id)).not_to include(old_user_id)
    end

    context 'when the school already has a pending ownership transfer' do
      before { create(:ownership_transfer, school:) }

      it 'does not change the owner' do
        task.invoke('old_owner@example.com', 'new_owner@example.com')

        expect(school.roles.owner.pluck(:user_id)).to include(old_user_id)
        expect(school.roles.owner.pluck(:user_id)).not_to include(new_user_id)
      end

      it 'rolls back the teacher role created for the new owner' do
        task.invoke('old_owner@example.com', 'new_owner@example.com')

        expect(school.roles.teacher.pluck(:user_id)).not_to include(new_user_id)
      end
    end
  end
end
