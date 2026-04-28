# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscriptions::PardotFormHandlerSubmitter do
  let(:endpoint_url) { 'https://example.com/form-handler' }
  let(:service) { described_class.new(endpoint_url: endpoint_url) }
  let(:payload) { { 'email' => 'teacher@example.com', 'privacy_policy' => true } }

  describe '#call' do
    let(:connection) { instance_double(Faraday::Connection) }
    let(:response) { instance_double(Faraday::Response, status: status, headers: headers, success?: success) }
    let(:headers) { {} }
    let(:status) { 200 }
    let(:success) { true }

    before do
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:post).and_return(response)
    end

    it 'returns success for a 200 response' do
      result = service.call(form_payload: payload)

      expect(result.success?).to be(true)
    end

    it 'returns success for a 302 success redirect location' do
      allow(response).to receive_messages(status: 302, success?: false, headers: { 'location' => '/subscriptions/success' })

      result = service.call(form_payload: payload)

      expect(result.success?).to be(true)
    end

    it 'returns rejected for a 302 error redirect location' do
      allow(response).to receive_messages(status: 302, success?: false, headers: { 'location' => '/subscriptions/error' })

      result = service.call(form_payload: payload)

      aggregate_failures do
        expect(result.success?).to be(false)
        expect(result.error_code).to eq('subscription_provider_rejected')
      end
    end

    it 'returns ambiguous for an unknown 302 redirect location' do
      allow(response).to receive_messages(status: 302, success?: false, headers: { 'location' => '/subscriptions/unknown' })

      result = service.call(form_payload: payload)

      aggregate_failures do
        expect(result.success?).to be(false)
        expect(result.error_code).to eq('subscription_provider_ambiguous')
      end
    end
  end
end
