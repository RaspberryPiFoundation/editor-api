# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeacherInvitation do
  include ActionMailer::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  it 'has a valid factory' do
    invitation = build(:teacher_invitation)

    expect(invitation).to be_valid
  end

  it 'is invalid with an incorrectly formatted email address' do
    invitation = build(:teacher_invitation, email_address: 'not-an-email-address')

    expect(invitation).not_to be_valid
  end

  it 'is invalid with an unverified school' do
    school = build(:school, verified_at: nil)
    invitation = build(:teacher_invitation, school:)

    expect(invitation).not_to be_valid
  end

  it 'sends an invitation email after create' do
    school = create(:verified_school)

    invitation = described_class.create!(email_address: 'teacher@example.com', school:)

    assert_enqueued_email_with InvitationMailer, :invite_teacher, params: { invitation: }
  end

  it 'generates a token for teacher invitation' do
    invitation = create(:teacher_invitation)
    token = invitation.generate_token_for(:teacher_invitation)

    expect(described_class.find_by_token_for(:teacher_invitation, token)).to eq(invitation)
  end

  it 'generates a token valid for 30 days' do
    invitation = create(:teacher_invitation)
    token = invitation.generate_token_for(:teacher_invitation)

    travel 31.days do
      expect(described_class.find_by_token_for(:teacher_invitation, token)).to be_nil
    end
  end

  it 'invalidates the token if the email address changes' do
    invitation = create(:teacher_invitation)
    token = invitation.generate_token_for(:teacher_invitation)

    invitation.update(email_address: 'new-email@example.com')

    expect(described_class.find_by_token_for(:teacher_invitation, token)).to be_nil
  end

  it 'delegates #school_name to School#name' do
    school = build(:school, name: 'school-name')
    invitation = build(:teacher_invitation, school:)

    expect(invitation.school_name).to eq('school-name')
  end

  it 'non-deterministically encrypts the email_address' do
    school = create(:verified_school)
    described_class.create!(email_address: 'teacher@example.com', school:)

    expect(described_class.find_by(email_address: 'teacher@example.com')).to be_nil
  end
end
