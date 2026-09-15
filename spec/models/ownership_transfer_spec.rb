# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OwnershipTransfer do
  include ActionMailer::TestHelper

  subject(:ownership_transfer) { build(:ownership_transfer, school:, nominated_user_id: nominee.id) }

  let(:school) { create(:verified_school) }
  let(:nominee) { create(:teacher, school:) }

  before do
    stub_user_info_api_fetch_by_ids(user_ids: [nominee.id])
  end

  describe 'validations' do
    it 'has a valid factory' do
      expect(ownership_transfer).to be_valid
    end

    it 'requires a school' do
      ownership_transfer.school = nil

      expect(ownership_transfer).not_to be_valid
    end

    it 'requires a nominated_user_id' do
      ownership_transfer.nominated_user_id = nil

      expect(ownership_transfer).not_to be_valid
    end

    it 'requires a requested_by_user_id' do
      ownership_transfer.requested_by_user_id = nil

      expect(ownership_transfer).not_to be_valid
    end

    it 'requires an email_address' do
      ownership_transfer.email_address = nil

      expect(ownership_transfer).not_to be_valid
    end

    it 'is invalid with an incorrectly formatted email address' do
      ownership_transfer.email_address = 'not-an-email-address'

      expect(ownership_transfer).not_to be_valid
    end

    it 'non-deterministically encrypts the email_address' do
      ownership_transfer.save!

      expect(described_class.find_by(email_address: ownership_transfer.email_address)).to be_nil
    end
  end

  describe 'status' do
    it 'defaults to pre_pending on a new record' do
      expect(ownership_transfer.status).to eq('pre_pending')
    end

    it 'is valid for every declared status' do
      described_class.statuses.each_key do |status|
        ownership_transfer.status = status

        expect(ownership_transfer).to be_valid
      end
    end

    it 'is invalid when set to a status outside the enum' do
      ownership_transfer.status = 'made-up-status'

      expect(ownership_transfer).not_to be_valid
    end

    it 'exposes a predicate for the current status' do
      described_class.statuses.each_key do |status|
        ownership_transfer.status = status

        expect(ownership_transfer.public_send("#{status}?")).to be true
      end
    end

    it 'exposes a scope per status' do
      described_class.statuses.each_key do |status|
        ownership_transfer.status = status
        ownership_transfer.save!

        expect(described_class.public_send(status)).to include(ownership_transfer)
      end
    end
  end

  describe 'nominee role validation' do
    it 'does not run when nominated_user_id is unchanged' do
      ownership_transfer.save!
      ownership_transfer.update!(status: :pending)

      # only the save! above should have looked up the nominee; the role check
      # is skipped on update since nominated_user_id isn't changing
      expect(UserInfoApiClient).to have_received(:fetch_by_ids).once
    end

    it 'is valid when the nominee has the teacher role for the school' do
      expect(ownership_transfer).to be_valid
    end

    it 'is valid when the nominee has the owner role for the school' do
      owner = create(:owner, school:)
      stub_user_info_api_fetch_by_ids(user_ids: [owner.id])
      ownership_transfer.nominated_user_id = owner.id

      expect(ownership_transfer).to be_valid
    end

    it 'is invalid when the nominee has only the student role for the school' do
      student = create(:student, school:)
      stub_user_info_api_fetch_by_ids(user_ids: [student.id])
      ownership_transfer.nominated_user_id = student.id

      expect(ownership_transfer).not_to be_valid
    end

    it 'is invalid when the nominee has a teacher role for a different school' do
      other_school = create(:verified_school)
      other_teacher = create(:teacher, school: other_school)
      stub_user_info_api_fetch_by_ids(user_ids: [other_teacher.id])
      ownership_transfer.nominated_user_id = other_teacher.id

      expect(ownership_transfer).not_to be_valid
    end

    it 'adds an error naming the nominated_user_id and the school id' do
      student = create(:student, school:)
      stub_user_info_api_fetch_by_ids(user_ids: [student.id])
      ownership_transfer.nominated_user_id = student.id

      ownership_transfer.valid?

      expect(ownership_transfer.errors[:nominated_user_id].first).to include(student.id)
      expect(ownership_transfer.errors[:nominated_user_id].first).to include(school.id)
    end
  end

  describe 'the request email' do
    it 'is enqueued with the transfer as the mailer param' do
      ownership_transfer.save!

      assert_enqueued_email_with(
        SchoolOwnershipMailer, :request_ownership_transfer, params: { ownership_transfer: }
      )
    end
  end
end
