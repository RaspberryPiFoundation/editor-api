# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolVerificationService do
  let(:school) { create(:school, creator_id: school_creator.id) }
  let(:user) { create(:user) }
  let(:school_creator) { create(:user) }
  let(:service) { described_class.new(school.id, user) }
  let(:organisation_id) { SecureRandom.uuid }

  describe '#verify' do
    before do
      service.verify
      school.reload
    end

    it 'sets verified_at to a date' do
      expect(school.verified_at).to be_a(ActiveSupport::TimeWithZone)
    end

    it 'grants the creator the owner role for the school' do
      expect(school_creator).to be_school_owner(school)
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
