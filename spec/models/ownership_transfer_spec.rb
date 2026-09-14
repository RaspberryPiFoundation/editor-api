# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OwnershipTransfer do
  include ActionMailer::TestHelper

  it 'has a valid factory' do
    ownership_transfer = build(:ownership_transfer)

    expect(ownership_transfer).to be_valid
  end

  it 'is invalid with an incorrectly formatted email address' do
    ownership_transfer = build(:ownership_transfer, email_address: 'not-an-email-address')

    expect(ownership_transfer).not_to be_valid
  end

  it 'sends an ownership transfer request email after create' do
    school = create(:verified_school)

    ownership_transfer = described_class.create!(email_address: 'new-owner@example.com', school:)

    assert_enqueued_email_with SchoolOwnershipMailer, :request_ownership_transfer, params: { ownership_transfer: }
  end

  it 'delegates #school_name to School#name' do
    school = build(:school, name: 'school-name')
    ownership_transfer = build(:ownership_transfer, school:)

    expect(ownership_transfer.school_name).to eq('school-name')
  end

  it 'non-deterministically encrypts the email_address' do
    school = create(:verified_school)
    described_class.create!(email_address: 'new-owner@example.com', school:)

    expect(described_class.find_by(email_address: 'new-owner@example.com')).to be_nil
  end
end
