# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /test/reseed' do
  subject(:request) { post('/test/reseed', headers: headers) }

  let(:headers) { { 'X-RESEED-API-KEY' => ENV['RESEED_API_KEY'] } }

  before do
    Rails.application.load_tasks
    host! 'test-editor-api.raspberrypi.org'
  end

  it 'returns OK' do
    request
    expect(response).to be_ok
  end

  it 'destroys the test seeds' do
    expect(Rake::Task['test_seeds:destroy']).to receive(:invoke).and_call_original
    request
  end

  it 'recreates the test seeds' do
    expect(Rake::Task['test_seeds:create']).to receive(:invoke).and_call_original
    request
  end

  context 'when the host is not allowed' do
    before do
      host! 'editor-api.raspberrypi.org'
    end

    it 'returns not found' do
      request
      expect(response).to be_not_found
    end

    it 'does not destroy test seeds' do
      expect(Rake::Task['test_seeds:destroy']).not_to receive(:invoke)
      request
    end

    it 'does not recreate test seeds' do
      expect(Rake::Task['test_seeds:create']).not_to receive(:invoke)
      request
    end
  end

  context 'when the RESEED_API_KEY is not provided' do
    let(:headers) { {} }

    it 'returns not found' do
      request
      expect(response).to be_not_found
    end

    it 'does not destroy test seeds' do
      expect(Rake::Task['test_seeds:destroy']).not_to receive(:invoke)
      request
    end

    it 'does not recreate test seeds' do
      expect(Rake::Task['test_seeds:create']).not_to receive(:invoke)
      request
    end
  end

  context 'when the RESEED_API_KEY is incorrect' do
    let(:headers) { { 'X-RESEED-API-KEY' => 'my_dodgy_api_key' } }

    it 'returns not found' do
      request
      expect(response).to be_not_found
    end

    it 'does not destroy test seeds' do
      expect(Rake::Task['test_seeds:destroy']).not_to receive(:invoke)
      request
    end

    it 'does not recreate test seeds' do
      expect(Rake::Task['test_seeds:create']).not_to receive(:invoke)
      request
    end
  end

  context 'when requested in production' do
    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    it 'returns not found' do
      request
      expect(response).to be_not_found
    end

    it 'does not destroy test seeds' do
      expect(Rake::Task['test_seeds:destroy']).not_to receive(:invoke)
      request
    end

    it 'does not recreate test seeds' do
      expect(Rake::Task['test_seeds:create']).not_to receive(:invoke)
      request
    end
  end
end