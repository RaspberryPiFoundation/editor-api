# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOnboardingService do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school, creator_id: school_creator.id) }
  let(:school_creator) { create(:user) }
  let(:service) { described_class.new(school) }

  before do
    authenticated_in_hydra_as(school_creator)
    allow(ProfileApiClient).to receive(:create_school)
    stub_profile_api_create_safeguarding_flag
  end

  describe '#onboard' do
    describe 'when onboarding is successful' do
      it 'grants the creator the owner role for the school' do
        service.onboard(token:)
        expect(school_creator).to be_school_owner(school)
      end

      it 'grants the creator the teacher role for the school' do
        service.onboard(token:)
        expect(school_creator).to be_school_teacher(school)
      end

      it 'creates the school in Profile API' do
        service.onboard(token:)
        expect(ProfileApiClient).to have_received(:create_school).with(token:, id: school.id, code: school.code)
      end

      it 'creates the owner safeguarding flag for the creator' do
        service.onboard(token:)
        expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token:, flag: 'school:owner', email: school_creator.email, school_id: school.id)
      end

      it 'creates the teacher safeguarding flag for the creator' do
        service.onboard(token:)
        expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token:, flag: 'school:teacher', email: school_creator.email, school_id: school.id)
      end

      it 'creates the school in Profile API before the safeguarding flags' do
        profile_api_calls = []
        allow(ProfileApiClient).to receive(:create_school) { profile_api_calls << :create_school }
        allow(ProfileApiClient).to receive(:create_safeguarding_flag) { profile_api_calls << :create_safeguarding_flag }

        service.onboard(token:)
        expect(profile_api_calls.first).to eq(:create_school)
      end
    end

    describe 'when the school cannot be created in Profile API' do
      before do
        allow(ProfileApiClient).to receive(:create_school).and_raise(RuntimeError)
      end

      it 'does not create owner role' do
        suppress(RuntimeError) { service.onboard(token:) }
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        suppress(RuntimeError) { service.onboard(token:) }
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'raises the underlying error' do
        expect { service.onboard(token:) }.to raise_error(RuntimeError)
      end
    end

    describe 'when Profile API returns unauthorized' do
      before do
        allow(ProfileApiClient).to receive(:create_school).and_raise(ProfileApiClient::UnauthorizedError)
      end

      it 'does not create owner role' do
        suppress(ProfileApiClient::UnauthorizedError) { service.onboard(token:) }
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        suppress(ProfileApiClient::UnauthorizedError) { service.onboard(token:) }
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'raises the underlying error' do
        expect { service.onboard(token:) }.to raise_error(ProfileApiClient::UnauthorizedError)
      end
    end

    describe 'when the safeguarding flags cannot be created in Profile API' do
      before do
        allow(ProfileApiClient).to receive(:create_safeguarding_flag).and_raise(RuntimeError)
      end

      it 'does not create owner role' do
        suppress(RuntimeError) { service.onboard(token:) }
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        suppress(RuntimeError) { service.onboard(token:) }
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'raises the underlying error' do
        expect { service.onboard(token:) }.to raise_error(RuntimeError)
      end
    end

    describe 'when teacher and owner roles cannot be created because they already have a role in another school' do
      let(:another_school) { create(:school) }

      before do
        create(:role, user_id: school.creator_id, school: another_school)
      end

      it 'does not create owner role' do
        suppress(ActiveRecord::RecordInvalid) { service.onboard(token:) }
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        suppress(ActiveRecord::RecordInvalid) { service.onboard(token:) }
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'does not create school in Profile API' do
        suppress(ActiveRecord::RecordInvalid) { service.onboard(token:) }
        expect(ProfileApiClient).not_to have_received(:create_school)
      end

      it 'raises the underlying error' do
        expect { service.onboard(token:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
