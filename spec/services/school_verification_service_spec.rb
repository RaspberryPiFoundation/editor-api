# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolVerificationService do
  let(:website) { 'http://example.com' }
  let(:school) { build(:school, creator_id: school_creator.id, website:) }
  let(:school_creator) { create(:user) }
  let(:service) { described_class.new(school) }

  around do |example|
    ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: 'true') do
      example.run
    end
  end

  describe '#verify' do
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
