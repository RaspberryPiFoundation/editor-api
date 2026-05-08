# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscriptions::TurnstileVerifier do
  let(:secret_key) { 'test-secret' }
  let(:remote_ip) { '127.0.0.1' }
  let(:token) { 'test-token' }
  let(:verifier) { described_class.new(token:, remote_ip:, secret_key:) }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:response) do
    instance_double(Faraday::Response, success?: true, status: 200, body: { success: true }.to_json)
  end

  before do
    allow(verifier).to receive(:faraday).and_return(connection)
    allow(connection).to receive(:post).and_return(response)
    allow(Sentry).to receive(:capture_exception)
  end

  describe '#passed?' do
    it 'posts to Cloudflare siteverify with the correct params' do
      verifier.passed?

      expect(connection).to have_received(:post).with(
        described_class::API_URL,
        { secret: secret_key, response: token, remoteip: remote_ip }
      )
    end

    context 'when turnstile token is missing' do
      let(:token) { '' }

      it 'returns false without calling Cloudflare' do
        expect(verifier.passed?).to be(false)
        expect(connection).not_to have_received(:post)
      end
    end

    context 'when turnstile token is valid' do
      it { expect(verifier.passed?).to be(true) }
    end

    context 'when Cloudflare rejects the token' do
      let(:response) do
        instance_double(Faraday::Response, success?: true, status: 200, body: { success: false }.to_json)
      end

      it { expect(verifier.passed?).to be(false) }
    end

    context 'when Cloudflare returns a server error' do
      let(:response) do
        instance_double(Faraday::Response, success?: false, status: 500, body: 'Internal Server Error')
      end

      it { expect(verifier.passed?).to be(true) }
    end

    context 'when Cloudflare returns malformed JSON' do
      let(:response) do
        instance_double(Faraday::Response, success?: true, status: 200, body: 'not-json')
      end

      it { expect(verifier.passed?).to be(true) }

      it 'reports the error to Sentry' do
        verifier.passed?
        expect(Sentry).to have_received(:capture_exception).with(be_a(JSON::ParserError))
      end
    end

    context 'when the Cloudflare connection fails' do
      before do
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed.new('connection failed'))
      end

      it { expect(verifier.passed?).to be(true) }

      it 'reports the error to Sentry' do
        verifier.passed?
        expect(Sentry).to have_received(:capture_exception).with(be_a(Faraday::Error))
      end
    end
  end
end
