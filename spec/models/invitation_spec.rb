# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invitation do
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
end
