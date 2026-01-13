# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolOnboardingService do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school, creator_id: school_creator.id) }
  let(:school_creator) { create(:user) }
  let(:service) { described_class.new(school) }

  before do
    allow(ProfileApiClient).to receive(:create_school)
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

      it 'returns true' do
        expect(service.onboard(token:)).to be(true)
      end
    end

    describe 'when the school cannot be created in Profile API' do
      before do
        allow(ProfileApiClient).to receive(:create_school).and_raise(RuntimeError)
      end

      it 'does not create owner role' do
        service.onboard(token:)
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        service.onboard(token:)
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'returns false' do
        expect(service.onboard(token:)).to be(false)
      end
    end

    describe 'when teacher and owner roles cannot be created because they already have a role in another school' do
      let(:another_school) { create(:school) }

      before do
        create(:role, user_id: school.creator_id, school: another_school)
      end

      it 'does not create owner role' do
        service.onboard(token:)
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        service.onboard(token:)
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'does not create school in Profile API' do
        service.onboard(token:)
        expect(ProfileApiClient).not_to have_received(:create_school)
      end

      it 'returns false' do
        expect(service.onboard(token:)).to be(false)
      end
    end
  end
end
