# frozen_string_literal: true

require 'rails_helper'

describe CorpMiddleware do
  let(:app) { instance_double(App::Application) }
  let(:middleware) { described_class.new(app) }
  let(:env) { { 'HTTP_HOST' => 'test.com', 'PATH_INFO' => '/rails/active_storage' } }

  before do
    allow(app).to receive(:call).and_return([200, {}, ['OK']])
    allow(ENV).to receive(:[]).with('ALLOWED_ORIGINS').and_return('test.com')
  end

  it 'sets the Cross-Origin-Resource-Policy header for a literal origin' do
    _status, headers, _response = middleware.call(env)

    expect(headers['Cross-Origin-Resource-Policy']).to eq('cross-origin')
  end

  it 'sets the Cross-Origin-Resource-Policy header for regex origin' do
    allow(ENV).to receive(:[]).with('ALLOWED_ORIGINS').and_return('/test\.com/')

    _status, headers, _response = middleware.call(env)

    expect(headers['Cross-Origin-Resource-Policy']).to eq('cross-origin')
  end

  it 'does not set the Cross-Origin-Resource-Policy header for disallowed origins' do
    allow(ENV).to receive(:[]).with('ALLOWED_ORIGINS').and_return('other.com')

    _status, headers, _response = middleware.call(env)

    expect(headers).not_to have_key('Cross-Origin-Resource-Policy')
  end
end
