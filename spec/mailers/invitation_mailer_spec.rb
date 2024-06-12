# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvitationMailer do
  describe 'invite_teacher' do
    subject(:email) { described_class.with(invitation:).invite_teacher }

    let(:invitation) { create(:invitation) }

    before do
      allow(ENV).to receive(:fetch).with('EDITOR_PUBLIC_URL').and_return('http://example.com')
    end

    it 'includes the school name in the body' do
      expect(email.body.to_s).to include(invitation.school.name)
    end

    it 'includes a link to redeem the invitation in the body' do
      allow(invitation).to receive(:generate_token_for).and_return('token-id')

      expect(email.body.to_s).to include('http://example.com/en/invitations/token-id')
    end

    it 'includes the school name in the subject' do
      expect(email.subject).to include(invitation.school.name)
    end
  end
end
