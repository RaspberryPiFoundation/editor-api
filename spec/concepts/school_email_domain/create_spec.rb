# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolEmailDomain::Create, type: :unit do
  let(:school) { create(:school) }
  let(:domain) { 'school.edu' }
  let(:token) { UserProfileMock::TOKEN }

  before { stub_profile_api_update_school_email_domains }

  context 'with valid values' do
    it 'returns a successful operation response' do
      response = described_class.call(school:, domain:, token:)
      expect(response.success?).to be(true)
    end

    it 'creates a school email domain' do
      expect { described_class.call(school:, domain:, token:) }.to change(SchoolEmailDomain, :count).by(1)
    end

    it 'returns the domain in the operation response' do
      response = described_class.call(school:, domain:, token:)
      expect(response[:school_email_domain]).to be_a(SchoolEmailDomain)
    end

    it 'assigns the domain' do
      response = described_class.call(school:, domain:, token:)
      expect(response[:school_email_domain].domain).to eq(domain)
    end

    it 'assigns the school' do
      response = described_class.call(school:, domain:, token:)
      expect(response[:school_email_domain].school_id).to eq(school.id)
    end

    it 'syncs the domains to Profile' do
      described_class.call(school:, domain:, token:)
      expect(ProfileApiClient).to have_received(:update_school_email_domains).with(
        token:,
        school_id: school.id,
        school_email_domains: [domain]
      )
    end

    it 'acquires an advisory lock while creating and syncing to Profile' do
      allow(SchoolEmailDomain.connection).to receive(:execute).and_call_original
      described_class.call(school:, domain:, token:)
      lock_key = Zlib.crc32("#{SchoolEmailDomain::Create::LOCK_NAMESPACE}:#{school.id}")
      expect(SchoolEmailDomain.connection).to have_received(:execute).with("SELECT pg_advisory_xact_lock(#{lock_key})")
    end

    context 'when multiple domains already exist' do
      before do
        create(:school_email_domain, school:, domain: 'first.edu')
        create(:school_email_domain, school:, domain: 'second.edu')
        create(:school_email_domain, school:, domain: 'third.edu')
      end

      it 'syncs all domains to Profile' do
        described_class.call(school:, domain:, token:)
        expect(ProfileApiClient).to have_received(:update_school_email_domains).with(
          token:,
          school_id: school.id,
          school_email_domains: ['first.edu', 'second.edu', 'third.edu', domain]
        )
      end
    end
  end

  shared_examples 'an invalid record' do
    before { allow(Sentry).to receive(:capture_exception) }

    it 'does not create a school email domain' do
      expect { described_class.call(school:, domain:, token:) }.not_to change(SchoolEmailDomain, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, domain:, token:)
      expect(response.failure?).to be(true)
    end

    it 'does not send the exception to Sentry' do
      described_class.call(school:, domain:, token:)
      expect(Sentry).not_to have_received(:capture_exception).with(kind_of(StandardError))
    end

    it 'returns the error code in the operation response' do
      response = described_class.call(school:, domain:, token:)
      expect(response[:error_code]).to eq(expected_error_code)
    end

    it 'does not attempt to update Profile' do
      described_class.call(school:, domain:, token:)
      expect(ProfileApiClient).not_to have_received(:update_school_email_domains)
    end
  end

  context 'when domain is blank' do
    let(:domain) { '' }
    let(:expected_error_code) { 'blank' }

    it_behaves_like 'an invalid record'
  end

  context 'when domain is not an FQDN' do
    let(:domain) { 'edu' }
    let(:expected_error_code) { 'invalid_host' }

    it_behaves_like 'an invalid record'
  end

  context 'when domain has an invalid URI' do
    let(:domain) { 'exa mple.com' }
    let(:expected_error_code) { 'invalid_uri' }

    it_behaves_like 'an invalid record'
  end

  context 'when domain has an invalid public suffix' do
    let(:domain) { 'co.uk' }
    let(:expected_error_code) { 'invalid_public_suffix' }

    it_behaves_like 'an invalid record'
  end

  context 'when domain is a duplicate' do
    before { create(:school_email_domain, school:, domain:) }

    let(:expected_error_code) { 'taken' }

    it_behaves_like 'an invalid record'
  end

  context 'when a concurrent request creates the same domain' do
    let(:expected_error_code) { 'taken' }
    let(:school_email_domain) { SchoolEmailDomain.new(school:, domain:) }

    before do
      allow(Sentry).to receive(:capture_exception)
      allow(school.school_email_domains).to receive(:build).with(domain:).and_return(school_email_domain)
      allow(school_email_domain).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
    end

    it_behaves_like 'an invalid record'
  end

  context 'when Profile sync fails' do
    let(:profile_error) do
      ProfileApiClient::UnexpectedResponse.new(
        instance_double(Faraday::Response, status: 500, headers: {}, body: '')
      )
    end

    before do
      allow(Sentry).to receive(:capture_exception)

      allow(ProfileApiClient).to receive(:update_school_email_domains)
        .and_raise(profile_error)
    end

    it 'attempts to sync to Profile' do
      described_class.call(school:, domain:, token:)
      expect(ProfileApiClient).to have_received(:update_school_email_domains).once
    end

    it 'does not persist the domain' do
      expect { described_class.call(school:, domain:, token:) }
        .not_to change(SchoolEmailDomain, :count)
    end

    it 'sends the exception to Sentry' do
      described_class.call(school:, domain:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end

    it 'returns a failed operation response' do
      expect(described_class.call(school:, domain:, token:)).to be_failure
    end

    it 'returns the error code in the operation response' do
      response = described_class.call(school:, domain:, token:)
      expect(response[:error_code]).to eq('profile_sync_failed')
    end
  end
end
