# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolEmailDomain do
  subject(:school_email_domain) { described_class.create!(school:, domain:) }

  let(:school) { create(:school, creator_id: SecureRandom.uuid) }
  let(:domain) { 'example.edu' }

  describe 'associations' do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to be_valid }
  end

  context 'with a valid domain' do
    it 'accepts the domain' do
      expect(school_email_domain.domain).to eq('example.edu')
    end

    describe 'domain normalisation' do
      let(:domain) { '@EXAMPLE.EDU.' }

      it 'normalises a domain' do
        expect(school_email_domain.domain).to eq('example.edu')
      end
    end

    describe 'domain uniqueness' do
      context 'when the proposed domain matches the existing record' do
        subject(:school_email_domain) { described_class.new(school:, domain:) }

        let(:domain) { 'example.edu' }

        before do
          described_class.create!(school:, domain: 'example.edu')
          school_email_domain.valid?
        end

        it 'rejects the duplicate' do
          expect(school_email_domain).not_to be_valid
        end

        it 'records :taken on domain' do
          expect(school_email_domain.errors.of_kind?(:domain, :taken)).to be(true)
        end
      end

      context 'when the proposed domain matches after normalisation' do
        subject(:school_email_domain) { described_class.new(school:, domain:) }

        let(:domain) { 'http://EXAMPLE.EDU' }

        before do
          described_class.create!(school:, domain: 'example.edu')
          school_email_domain.valid?
        end

        it 'rejects the duplicate' do
          expect(school_email_domain).not_to be_valid
        end

        it 'records :taken on domain' do
          expect(school_email_domain.errors.of_kind?(:domain, :taken)).to be(true)
        end
      end

      it 'allows the same domain for a different school' do
        described_class.create!(school:, domain: 'example.edu')
        other_school = create(:school, creator_id: SecureRandom.uuid)
        other_school_email_domain = described_class.new(school: other_school, domain: 'example.edu')

        expect(other_school_email_domain).to be_valid
      end
    end
  end

  context 'with an invalid domain' do
    it { is_expected.not_to allow_value('').for(:domain) }
    it { is_expected.not_to allow_value('   ').for(:domain) }
    it { is_expected.not_to allow_value('http://').for(:domain) }
    it { is_expected.not_to allow_value('edu').for(:domain) }
    it { is_expected.not_to allow_value('com').for(:domain) }
    it { is_expected.not_to allow_value('co.uk').for(:domain) }
    it { is_expected.not_to allow_value('http://invalid uri').for(:domain) }
    it { is_expected.not_to allow_value('-wrong.edu').for(:domain) }
  end
end
