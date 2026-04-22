# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolEmailDomain do
  subject { described_class.new(school:, domain: 'example.edu') }

  let(:school) { create(:school, creator_id: SecureRandom.uuid) }

  it { is_expected.to belong_to(:school) }
  it { is_expected.to validate_presence_of(:domain) }

  describe 'domain normalisation' do
    it 'takes the host from an http URL before other normalisation' do
      record = described_class.new(school:, domain: 'http://mail.school.edu/path?query=1')
      record.valid?

      expect(record.domain).to eq('mail.school.edu')
    end

    it 'takes the host from an https URL before other normalisation' do
      record = described_class.new(school:, domain: 'https://EXAMPLE.EDU/')
      record.valid?

      expect(record.domain).to eq('example.edu')
    end

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

  describe 'public suffix list validation' do
    context 'when the hostname is only a suffix' do
      it 'rejects com' do
        record = described_class.new(school:, domain: 'com')
        record.valid?

        expect(record).not_to be_valid
        expect(record.errors.of_kind?(:domain, :invalid)).to be(true)
      end

      it 'rejects edu' do
        record = described_class.new(school:, domain: 'edu')
        record.valid?

        expect(record).not_to be_valid
        expect(record.errors.of_kind?(:domain, :invalid)).to be(true)
      end

      it 'rejects co.uk' do
        record = described_class.new(school:, domain: 'co.uk')
        record.valid?

        expect(record).not_to be_valid
        expect(record.errors.of_kind?(:domain, :invalid)).to be(true)
      end
    end

    context 'when there is at least one registrable label before the public suffix' do
      it 'accepts a typical school-style .edu domain' do
        record = described_class.new(school:, domain: 'example.edu')
        expect(record).to be_valid
      end

      it 'accepts a subdomain' do
        record = described_class.new(school:, domain: 'mail.example.edu')
        expect(record).to be_valid
      end

      it 'accepts a hostname under a multi-part public suffix' do
        record = described_class.new(school:, domain: 'school.example.co.uk')
        expect(record).to be_valid
      end

      it 'accepts district-style hosts' do
        record = described_class.new(school:, domain: 'school.k12.tx.us')
        expect(record).to be_valid
      end
    end
  end

  describe 'domain uniqueness' do
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
