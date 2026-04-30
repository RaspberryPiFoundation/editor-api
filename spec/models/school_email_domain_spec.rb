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
    describe 'domain normalisation' do
      context 'when given a full url' do
        let(:domain) { 'http://mail.school.edu/path?query=1' }

        it 'extracts the host' do
          expect(school_email_domain.domain).to eq('mail.school.edu')
        end
      end

      context 'when given a full https url' do
        let(:domain) { 'https://mail.school.edu/path' }

        it 'extracts the host' do
          expect(school_email_domain.domain).to eq('mail.school.edu')
        end
      end

      context 'when given a domain with a trailing dot' do
        let(:domain) { 'EXAMPLE.EDU.' }

        it 'stores the host without the trailing dot' do
          expect(school_email_domain.domain).to eq('example.edu')
        end
      end

      context 'when given a capitalised host' do
        let(:domain) { 'EXAMPLE.EDU' }

        it 'downcases the host' do
          expect(school_email_domain.domain).to eq('example.edu')
        end
      end

      context 'with a leading @' do
        let(:domain) { '@example.edu' }

        it 'removes the @' do
          expect(school_email_domain.domain).to eq('example.edu')
        end
      end
    end

    describe 'public suffix list validation' do
      context 'when there is at least one registrable label before the public suffix' do
        let(:domain) { 'example.edu' }

        it 'accepts the domain' do
          expect(school_email_domain.domain).to eq('example.edu')
        end
      end

      context 'when there is a subdomain before a valid public suffix' do
        let(:domain) { 'mail.example.edu' }

        it 'accepts the domain' do
          expect(school_email_domain.domain).to eq('mail.example.edu')
        end
      end

      context 'when there is a hostname under a multi-part public suffix' do
        let(:domain) { 'school.example.co.uk' }

        it 'accepts the domain' do
          expect(school_email_domain.domain).to eq('school.example.co.uk')
        end
      end

      context 'when given a district-style host with a multi-part public suffix' do
        let(:domain) { 'school.k12.tx.us' }

        it 'accepts the domain' do
          expect(school_email_domain.domain).to eq('school.k12.tx.us')
        end
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
    it { is_expected.not_to allow_value('edu').for(:domain) }
    it { is_expected.not_to allow_value('com').for(:domain) }
    it { is_expected.not_to allow_value('co.uk').for(:domain) }
    it { is_expected.not_to allow_value('http://invalid uri').for(:domain) }
  end
end
