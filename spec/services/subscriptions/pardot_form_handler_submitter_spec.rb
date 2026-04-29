# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscriptions::PardotFormHandlerSubmitter do
  let(:endpoint_url) { 'https://example.test/form-handler' }
  let(:submitter) { described_class.new(endpoint_url:) }
  let(:connection) { instance_double(Faraday::Connection) }

  let(:payload) do
    {
      'email' => 'teacher@example.com',
      'test_opt_in' => true,
      'privacy_policy' => true
    }
  end

  let(:headers) { {} }
  let(:response_body) { '' }
  let(:response_status) { 200 }
  let(:response) { instance_double(Faraday::Response, status: response_status, body: response_body, headers:) }

  before do
    allow(submitter).to receive(:faraday).and_return(connection)
    allow(connection).to receive(:post).and_return(response)
    allow(Sentry).to receive(:capture_exception)
  end

  describe '#call' do
    it 'returns success when status 200 and body contains success marker' do
      allow(response).to receive(:body).and_return('Cannot find success page to redirect to.')

      result = submitter.call(form_payload: payload)

      expect(result.success?).to be(true)
    end

    it 'returns rejected when body contains error marker even with status 200' do
      allow(response).to receive(:body).and_return('Cannot find error page to redirect to.')

      result = submitter.call(form_payload: payload)

      expect(result.success?).to be(false)
      expect(result.status).to eq(:bad_gateway)
      expect(result.error_code).to eq('subscription_provider_rejected')
    end

    it 'returns rejected when status is not 200' do
      allow(response).to receive(:status).and_return(302)

      result = submitter.call(form_payload: payload)

      expect(result.success?).to be(false)
      expect(result.status).to eq(:bad_gateway)
      expect(result.error_code).to eq('subscription_provider_rejected')
    end

    it 'returns ambiguous when status is 200 and body has no markers' do
      allow(response).to receive(:body).and_return('ok')

      result = submitter.call(form_payload: payload)

      expect(result.success?).to be(false)
      expect(result.status).to eq(:bad_gateway)
      expect(result.error_code).to eq('subscription_provider_ambiguous')
    end

    it 'returns unavailable on Faraday::Error' do
      allow(connection).to receive(:post).and_raise(Faraday::Error, 'connection failed')

      result = submitter.call(form_payload: payload)

      expect(result.success?).to be(false)
      expect(result.status).to eq(:service_unavailable)
      expect(result.error_code).to eq('subscription_provider_unavailable')
      expect(Sentry).to have_received(:capture_exception)
    end

    it 'returns not configured when endpoint_url is blank' do
      blank_submitter = described_class.new(endpoint_url: '')

      result = blank_submitter.call(form_payload: payload)

      expect(result.success?).to be(false)
      expect(result.status).to eq(:service_unavailable)
      expect(result.error_code).to eq('subscription_provider_not_configured')
    end

    it 'posts payload mapped to email and Tester only' do
      submitter.call(form_payload: payload)

      expect(connection).to have_received(:post).with(
        endpoint_url,
        {
          'email' => 'teacher@example.com',
          'Tester' => true
        }
      )
    end
  end
end
