# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sentry do
  describe 'before_send' do
    let(:event) { Sentry::ErrorEvent.new(configuration: described_class.configuration, integration_meta: nil) }

    def fingerprint_for(exception)
      described_class.configuration.before_send.call(event, { exception: }).fingerprint
    end

    it 'groups Faraday errors by class and request host' do
      exception = Faraday::ServerError.new('boom')
      exception.extend(RecordRequestHostInErrors::RequestHost)
      exception.request_host = 'api.example.com'

      expect(fingerprint_for(exception)).to eq(['Faraday::ServerError', 'api.example.com'])
    end

    it 'groups Faraday errors raised outside a request under an unknown host' do
      expect(fingerprint_for(Faraday::TimeoutError.new)).to eq(['Faraday::TimeoutError', 'unknown-host'])
    end

    it 'leaves other exceptions on the default grouping' do
      expect(fingerprint_for(StandardError.new)).to be_blank
    end
  end
end
