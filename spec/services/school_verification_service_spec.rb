# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolVerificationService do
  let(:website) { 'http://example.com' }
  let(:school) { build(:school, creator_id: school_creator.id, website:) }
  let(:school_creator) { create(:user) }
  let(:service) { described_class.new(school) }

  describe '#verify' do
    describe 'when immediate onboarding is enabled' do
      # TODO: Remove this block once the feature flag is retired
      around do |example|
        ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: 'true') do
          example.run
        end
      end

      describe 'when school can be saved' do
        it 'saves the school' do
          service.verify
          expect(school).to be_persisted
        end

        it 'sets verified_at to a date' do
          service.verify
          expect(school.reload.verified_at).to be_a(ActiveSupport::TimeWithZone)
        end

        it 'returns true' do
          expect(service.verify).to be(true)
        end
      end

      describe 'when school cannot be saved' do
        let(:website) { 'invalid' }

        it 'does not save the school' do
          service.verify
          expect(school).not_to be_persisted
        end

        it 'returns false' do
          expect(service.verify).to be(false)
        end
      end
    end

    # TODO: Remove these examples once the feature flag is retired
    describe 'when immediate onboarding is disabled' do
      let(:token) { 'token' }

      around do |example|
        ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: nil) do
          example.run
        end
      end

      before do
        allow(ProfileApiClient).to receive(:create_school)
      end

      describe 'when school can be saved' do
        it 'saves the school' do
          service.verify(token:)
          expect(school).to be_persisted
        end

        it 'sets verified_at to a date' do
          service.verify(token:)
          expect(school.reload.verified_at).to be_a(ActiveSupport::TimeWithZone)
        end

        it 'generates school code' do
          service.verify(token:)
          expect(school.reload.code).to be_present
        end

        it 'grants the creator the owner role for the school' do
          service.verify(token:)
          expect(school_creator).to be_school_owner(school)
        end

        it 'grants the creator the teacher role for the school' do
          service.verify(token:)
          expect(school_creator).to be_school_teacher(school)
        end

        it 'creates the school in Profile API' do
          service.verify(token:)
          expect(ProfileApiClient).to have_received(:create_school).with(token:, id: school.id, code: school.code)
        end

        it 'returns true' do
          expect(service.verify(token:)).to be(true)
        end
      end

      describe 'when school cannot be saved' do
        let(:website) { 'invalid' }

        it 'does not save the school' do
          service.verify(token:)
          expect(school).not_to be_persisted
        end

        it 'does not create owner role' do
          service.verify(token:)
          expect(school_creator).not_to be_school_owner(school)
        end

        it 'does not create teacher role' do
          service.verify(token:)
          expect(school_creator).not_to be_school_teacher(school)
        end

        it 'does not create school in Profile API' do
          expect(ProfileApiClient).not_to have_received(:create_school)
        end

        it 'returns false' do
          expect(service.verify(token:)).to be(false)
        end
      end

      describe 'when the school cannot be created in Profile API' do
        before do
          allow(ProfileApiClient).to receive(:create_school).and_raise(RuntimeError)
        end

        it 'does not save the school' do
          service.verify(token:)
          expect { school.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not create owner role' do
          service.verify(token:)
          expect(school_creator).not_to be_school_owner(school)
        end

        it 'does not create teacher role' do
          service.verify(token:)
          expect(school_creator).not_to be_school_teacher(school)
        end

        it 'does not create school in Profile API' do
          expect(ProfileApiClient).not_to have_received(:create_school)
        end

        it 'returns false' do
          expect(service.verify(token:)).to be(false)
        end
      end

      describe 'when teacher and owner roles cannot be created because they already have a role in another school' do
        let(:another_school) { create(:school) }

        before do
          create(:role, user_id: school.creator_id, school: another_school)
        end

        it 'does not save the school' do
          service.verify(token:)
          expect { school.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not create owner role' do
          service.verify(token:)
          expect(school_creator).not_to be_school_owner(school)
        end

        it 'does not create teacher role' do
          service.verify(token:)
          expect(school_creator).not_to be_school_teacher(school)
        end

        it 'does not create school in Profile API' do
          expect(ProfileApiClient).not_to have_received(:create_school)
        end

        it 'returns false' do
          expect(service.verify(token:)).to be(false)
        end
      end
    end
  end

  describe '#reject' do
    before do
      service.reject
      school.reload
    end

    it 'sets verified_at to nil' do
      expect(school.verified_at).to be_nil
    end

    it 'sets rejected_at to a date' do
      expect(school.rejected_at).to be_a(ActiveSupport::TimeWithZone)
    end
  end

  describe 'when the school was previously verified' do
    before do
      service.verify
      service.reject
      school.reload
    end

    it 'does not clear verified_at' do
      expect(school.verified_at).to be_present
    end

    it 'does not set rejected_at' do
      expect(school.rejected_at).to be_nil
    end
  end
end
