# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolVerificationService do
  let(:school) { create(:school) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(school.id, user) }
  let(:organisation_id) { SecureRandom.uuid }

  before do
    allow(ProfileApiClient).to receive(:create_organisation).and_return({ id: organisation_id })
  end

  describe '#verify' do
    before do
      service.verify
      school.reload
    end

    it 'sets organisation_id to the expected uuid' do
      expect(school.organisation_id).to eq(organisation_id)
    end

    it 'sets verified_at to a date' do
      expect(school.verified_at).to be_a(ActiveSupport::TimeWithZone)
    end
  end

  describe '#reject' do
    before do
      service.reject
      school.reload
    end

    it 'sets organisation_id to nil' do
      expect(school.organisation_id).to be_nil
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

    it 'sets organisation_id to nil' do
      expect(school.organisation_id).to be_nil
    end

    it 'sets verified_at to nil' do
      expect(school.verified_at).to be_nil
    end

    it 'sets rejected_at to a date' do
      expect(school.rejected_at).to be_a(ActiveSupport::TimeWithZone)
    end
  end
end
