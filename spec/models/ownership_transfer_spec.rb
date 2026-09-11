# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OwnershipTransfer do
  include ActionMailer::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  it 'has a valid factory' do
    ownership_transfer = build(:ownership_transfer)

    expect(ownership_transfer).to be_valid
  end

  it 'is invalid with an incorrectly formatted email address' do
    ownership_transfer = build(:ownership_transfer, email_address: 'not-an-email-address')

    expect(ownership_transfer).not_to be_valid
  end

  # TODO: add mailer test

  it 'generates a token for ownership transfer' do
    ownership_transfer = create(:ownership_transfer)
    token = ownership_transfer.generate_token_for(:ownership_transfer)

    expect(described_class.find_by_token_for(:ownership_transfer, token)).to eq(ownership_transfer)
  end

  it 'generates a token valid for 30 days' do
    ownership_transfer = create(:ownership_transfer)
    token = ownership_transfer.generate_token_for(:ownership_transfer)

    travel 31.days do
      expect(described_class.find_by_token_for(:ownership_transfer, token)).to be_nil
    end
  end

  it 'invalidates the token if the email address changes' do
    ownership_transfer = create(:ownership_transfer)
    token = ownership_transfer.generate_token_for(:ownership_transfer)

    ownership_transfer.update(email_address: 'different-owner@example.com')

    expect(described_class.find_by_token_for(:ownership_transfer, token)).to be_nil
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
