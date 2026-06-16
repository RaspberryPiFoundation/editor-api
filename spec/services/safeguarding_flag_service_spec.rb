# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SafeguardingFlagService do
  let(:school) { create(:school) }
  let(:token) { UserProfileMock::TOKEN }

  before do
    allow(ProfileApiClient).to receive(:create_safeguarding_flag)
  end

  describe '.create_for_school_roles' do
    context 'when the user is a school owner' do
      let(:user) { create(:owner, school:, token:) }

      it 'creates the school owner safeguarding flag' do
        described_class.create_for_school_roles(user:, school:)

        expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(
          token: user.token,
          flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner],
          email: user.email,
          school_id: school.id
        )
      end
    end

    context 'when the user is a school teacher' do
      let(:user) { create(:teacher, school:, token:) }

      it 'creates the school teacher safeguarding flag' do
        described_class.create_for_school_roles(user:, school:)

        expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(
          token: user.token,
          flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher],
          email: user.email,
          school_id: school.id
        )
      end
    end

    context 'when the user is a school student' do
      let(:user) { create(:student, school:, token:) }

      it 'does not create a safeguarding flag' do
        described_class.create_for_school_roles(user:, school:)

        expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag)
      end
    end
  end

  describe '.create_for_token' do
    let(:user) { create(:teacher, school:, token:) }

    before do
      allow(User).to receive(:from_token).with(token:).and_return(user)
    end

    it 'creates flags for the user identified by the token' do
      described_class.create_for_token(token:, school:)

      expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(
        token:,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher],
        email: user.email,
        school_id: school.id
      )
    end

    it 'does not look up a user without a token' do
      described_class.create_for_token(token: nil, school:)

      expect(User).not_to have_received(:from_token)
    end
  end

  describe '.create_for_roles' do
    it 'creates each requested teacher or owner flag' do
      described_class.create_for_roles(
        token:,
        email: 'user@example.com',
        school:,
        roles: %i[owner teacher student]
      )

      expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(
        token:,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner],
        email: 'user@example.com',
        school_id: school.id
      )
      expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(
        token:,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher],
        email: 'user@example.com',
        school_id: school.id
      )
    end

    it 'does not create flags without an email' do
      described_class.create_for_roles(token:, email: nil, school:, roles: %i[owner teacher])

      expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag)
    end
  end
end
