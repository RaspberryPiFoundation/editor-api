# frozen_string_literal: true

require 'rails_helper'

describe CorpMiddleware do
  around do |example|
    ClimateControl.modify(ALLOWED_ORIGINS: allowed_origins) { example.run }
  end

  before { allow(app).to receive(:call).and_return([200, {}, ['OK']]) }

  let(:app) { instance_double(App::Application) }
  let(:middleware) { described_class.new(app) }
  let(:env) { { 'HTTP_HOST' => 'test.com', 'PATH_INFO' => '/rails/active_storage' } }
  let(:allowed_origins) { 'test.com' }

  it 'sets the Cross-Origin-Resource-Policy header for a literal origin' do
    _status, headers, _response = middleware.call(env)

    expect(headers['Cross-Origin-Resource-Policy']).to eq('cross-origin')
  end

  it 'sets the Cross-Origin-Resource-Policy header for requests to scratch assets' do
    _status, headers, _response = middleware.call(env.merge('PATH_INFO' => '/api/scratch/assets/internalapi/asset/123/get/'))

    expect(headers['Cross-Origin-Resource-Policy']).to eq('cross-origin')
  end

  context 'when the origin is allowed by a regex' do
    let(:allowed_origins) { '/test\.com/' }

    it 'sets the Cross-Origin-Resource-Policy header' do
      _status, headers, _response = middleware.call(env)

      expect(headers['Cross-Origin-Resource-Policy']).to eq('cross-origin')
    end
  end

  context 'when the origin is not allowed' do
    let(:allowed_origins) { 'other.com' }

    it 'does not set the Cross-Origin-Resource-Policy header' do
      _status, headers, _response = middleware.call(env)

      expect(headers).not_to have_key('Cross-Origin-Resource-Policy')
    end
  end
end
