# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolEmailDomain do
  subject { described_class.new(school:, domain: 'example.edu') }

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

    it 'rejects a duplicate domain for the same school after normalisation' do
      described_class.create!(school:, domain: 'example.edu')
      duplicate = described_class.new(school:, domain: 'EXAMPLE.EDU')
      duplicate.valid?

      expect(duplicate.errors.of_kind?(:domain, :taken)).to be(true)
    end

    it 'allows the same domain for a different school' do
      described_class.create!(school:, domain: 'example.edu')
      other_school = create(:school, creator_id: SecureRandom.uuid)
      other = described_class.new(school: other_school, domain: 'example.edu')

      expect(other).to be_valid
    end
  end
end
