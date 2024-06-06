# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invitation do
  include ActionMailer::TestHelper

  it 'has a valid factory' do
    invitation = build(:invitation)

    expect(invitation).to be_valid
  end

  it 'is invalid with an incorrectly formatted email address' do
    invitation = build(:invitation, email_address: 'not-an-email-address')

    expect(invitation).not_to be_valid
  end

  it 'is invalid with an unverified school' do
    school = build(:school, verified_at: nil)
    invitation = build(:invitation, school:)

    expect(invitation).not_to be_valid
  end

  it 'sends an invitation email after create' do
    school = create(:school, verified_at: Time.zone.now)

    invitation = described_class.create!(email_address: 'teacher@example.com', school:)

    assert_enqueued_email_with InvitationMailer, :invite_teacher, params: { invitation: }
  end
end
