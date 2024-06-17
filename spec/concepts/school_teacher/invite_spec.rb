# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolTeacher::Invite, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school, verified_at: Time.zone.now) }
  let(:teacher_id) { SecureRandom.uuid }

  let(:school_teacher_params) do
    { email_address: 'teacher-to-invite@example.com' }
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_teacher_params:, token:)
    expect(response.success?).to be(true)
  end

  it 'creates an Invitation' do
    expect { described_class.call(school:, school_teacher_params:, token:) }.to change(Invitation, :count)
  end

  context 'when creation fails' do
    let(:school_teacher_params) do
      { email_address: 'invalid' }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_teacher_params:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_teacher_params:, token:)
      expect(response[:error]).to match(/Email address 'invalid' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_teacher_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  context 'when the school is not verified' do
    let(:school) { create(:school) }

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_teacher_params:, token:)
      expect(response[:error]).to match(/School is not verified/)
    end
  end
end
