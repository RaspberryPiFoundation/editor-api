# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExperienceCsServiceAuthenticator do
  subject(:authenticate) { described_class.authenticate(candidate) }

  before do
    allow(Rails.configuration.x.experience_cs).to receive(:service_api_key).and_return('service-api-key')
  end

  context 'with the configured API key' do
    let(:candidate) { 'service-api-key' }

    it 'returns an Experience CS service user', :aggregate_failures do
      expect(authenticate.id).to eq(described_class::USER_ID)
      expect(authenticate).to be_experience_cs_admin
    end
  end

  context 'with a different API key' do
    let(:candidate) { 'wrong-api-key' }

    it 'does not authenticate' do
      expect(authenticate).to be_nil
    end
  end

  context 'without a configured API key' do
    let(:candidate) { 'service-api-key' }

    it 'does not authenticate' do
      allow(Rails.configuration.x.experience_cs).to receive(:service_api_key).and_return(nil)

      expect(authenticate).to be_nil
    end
  end
end
