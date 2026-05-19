# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolEmailDomainValidator do
  describe '.call' do
    it 'returns success with a normalised host for a valid domain' do
      result = described_class.call('example.com')

      expect(result).to eq('example.com')
    end

    context 'with a valid domain' do
      it 'extracts the host for http' do
        result = described_class.call('http://mail.school.edu/path?query=1')
        expect(result).to eq('mail.school.edu')
      end

      it 'extracts the host for https' do
        result = described_class.call('https://mail.school.edu/path?query=1')
        expect(result).to eq('mail.school.edu')
      end

      it 'removes a trailing dot' do
        result = described_class.call('example.edu.')
        expect(result).to eq('example.edu')
      end

      it 'lowercases the host' do
        result = described_class.call('EXAMPLE.EDU')
        expect(result).to eq('example.edu')
      end

      it 'removes a leading @' do
        result = described_class.call('@example.edu')
        expect(result).to eq('example.edu')
      end

      it 'accepts a subdomain' do
        result = described_class.call('mail.example.edu')
        expect(result).to eq('mail.example.edu')
      end

      it 'accepts a hostname er a multi-part public suffix' do
        result = described_class.call('school.example.co.uk')
        expect(result).to eq('school.example.co.uk')
      end

      it 'accepts a district-style with a multi-part public suffix' do
        result = described_class.call('school.k12.tx.us')
        expect(result).to eq('school.k12.tx.us')
      end
    end

    context 'when the domain is blank' do
      it 'raises BlankDomain' do
        expect { described_class.call('') }.to raise_error(SchoolEmailDomainValidator::BlankDomainError)
      end
    end

    context 'when the domain has an invalid URI' do
      it 'raises InvalidURIError' do
        expect { described_class.call('https://exa mple.com') }.to raise_error(SchoolEmailDomainValidator::InvalidURIError)
      end
    end

    context 'when the host does not match accounts_host_format' do
      it 'raises InvalidHostError' do
        expect { described_class.call('school_domain.edu') }
          .to raise_error(SchoolEmailDomainValidator::InvalidHostError)
      end
    end

    context 'when the host fails PublicSuffix validation' do
      it 'raises PublicSuffixError' do
        expect { described_class.call('co.uk') }
          .to raise_error(SchoolEmailDomainValidator::PublicSuffixError)
      end
    end
  end
end
