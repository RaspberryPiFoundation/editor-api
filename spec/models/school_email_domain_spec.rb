# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolEmailDomain do
  let(:school) { create(:school, creator_id: SecureRandom.uuid) }

  it { is_expected.to belong_to(:school) }
  it { is_expected.to validate_presence_of(:domain) }

  describe 'domain normalisation' do
    it 'downcases the domain' do
      record = described_class.new(school:, domain: 'EXAMPLE.EDU')
      record.valid?

      expect(record.domain).to eq('example.edu')
    end

    it 'removes a leading @' do
      record = described_class.new(school:, domain: '@example.edu')
      record.valid?

      expect(record.domain).to eq('example.edu')
    end
  end
end
