# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolVerificationService do
  let(:school) { create(:school, creator_id: school_creator.id) }
  let(:user) { create(:user) }
  let(:school_creator) { create(:user) }
  let(:service) { described_class.new(school.id) }
  let(:organisation_id) { SecureRandom.uuid }

  describe '#verify' do
    describe 'when school can be saved' do
      it 'sets verified_at to a date' do
        service.verify
        expect(school.reload.verified_at).to be_a(ActiveSupport::TimeWithZone)
      end

      it 'grants the creator the owner role for the school' do
        service.verify
        expect(school_creator).to be_school_owner(school)
      end

      it 'grants the creator the teacher role for the school' do
        service.verify
        expect(school_creator).to be_school_teacher(school)
      end

      it 'returns true' do
        expect(service.verify).to be(true)
      end
    end

    describe 'when school cannot be saved' do
      before do
        school.update_attribute(:website, 'invalid') # rubocop:disable Rails/SkipsModelValidations
      end

      it 'does not set verified_at' do
        service.verify
        expect(school.reload.verified_at).to be_nil
      end

      it 'does not create owner role' do
        service.verify
        expect(school_creator).not_to be_school_owner(school)
      end

      it 'does not create teacher role' do
        service.verify
        expect(school_creator).not_to be_school_teacher(school)
      end

      it 'returns false' do
        expect(service.verify).to be(false)
      end
    end

    describe 'when the school cannot be found' do
      before do
        allow(Sentry).to receive(:capture_exception)
        allow(School).to receive(:find).with(school.id).and_raise(ActiveRecord::RecordNotFound)
        service.verify
      end

      it 'reports the error in Sentry' do
        expect(Sentry).to have_received(:capture_exception)
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

    it 'sets verified_at to nil' do
      expect(school.verified_at).to be_nil
    end

    it 'sets rejected_at to a date' do
      expect(school.rejected_at).to be_a(ActiveSupport::TimeWithZone)
    end
  end
end
