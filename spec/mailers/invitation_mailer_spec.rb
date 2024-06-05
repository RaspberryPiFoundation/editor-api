# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvitationMailer do
  describe 'invite_teacher' do
    subject(:email) { described_class.with(invitation:).invite_teacher }

    let(:invitation) { create(:invitation) }

    it 'includes the school name in the body' do
      expect(email.body.to_s).to include(invitation.school.name)
    end

    it 'includes the school name in the subject' do
      expect(email.subject).to include(invitation.school.name)
    end
  end
end
