# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SalesforceSyncJob do
  describe '#perform' do
    let(:school) do
      create(:school,
             name: 'West Beverly Hills High School',
             website: 'https://example.com',
             address_line_1: '16711 Mulholland Drive',
             address_line_2: nil,
             municipality: 'Beverly Hills',
             administrative_area: 'California',
             postal_code: '90210',
             country_code: 'US')
    end

    let(:mock_client) { instance_double(Restforce::Client) }

    let(:expected_account_data) do
      {
        Name: 'West Beverly Hills High School',
        Website: 'https://example.com',
        BillingStreet: '16711 Mulholland Drive',
        BillingCity: 'Beverly Hills',
        BillingState: 'California',
        BillingPostalCode: '90210',
        BillingCountryCode: 'US',
        Industry: 'Education'
      }
    end

    before do
      stub_const('ENV', {
                   'SALESFORCE_USERNAME' => 'salesforce-username',
                   'SALESFORCE_PASSWORD' => 'salesforce-password',
                   'SALESFORCE_CLIENT_ID' => 'salesforce-client-id',
                   'SALESFORCE_CLIENT_SECRET' => 'salesforce-client-secret',
                   'SALESFORCE_HOST' => 'example.com'
                 })

      allow(Restforce).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:create)
    end

    it 'creates a Salesforce account with correct data' do
      described_class.perform_now(school.id)

      expect(mock_client).to have_received(:create).with('Account', expected_account_data)
    end

    it 'concatenates the address fields' do
      school.update(address_line_2: 'Address line 2')
      expected_data = expected_account_data.merge(BillingStreet: "16711 Mulholland Drive\nAddress line 2")

      described_class.perform_now(school.id)

      expect(mock_client).to have_received(:create).with('Account', expected_data)
    end

    it 'configures Restforce client with correct credentials' do
      described_class.perform_now(school.id)

      expect(Restforce).to have_received(:new).with(
        username: 'salesforce-username',
        password: 'salesforce-password',
        client_id: 'salesforce-client-id',
        client_secret: 'salesforce-client-secret',
        host: 'example.com',
        api_version: '57.0'
      )
    end

    it 'raises error when school is not found' do
      expect { described_class.perform_now('not-an-id') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
