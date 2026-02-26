# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /test/reseed' do
  subject(:request) { post('/test/reseed', headers:) }

  let(:headers) { { 'X-RESEED-API-KEY' => ENV.fetch('RESEED_API_KEY', nil) } }

  before do
    allow(Rake::Task['test_seeds:destroy']).to receive(:execute)
    allow(Rake::Task['test_seeds:create']).to receive(:execute)

    host! 'test-editor-api.raspberrypi.org'
    ENV['RESEED_API_KEY'] = 'my_test_api_key'
  end

  around do |example|
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction

    DatabaseCleaner.cleaning do
      Rails.application.load_tasks
      example.run
      Rake::Task.clear
    end
  end

  after do
    ENV.delete('RESEED_API_KEY')
  end

  it 'returns OK' do
    request
    expect(response).to be_ok
  end

  it 'destroys the test seeds' do
    request
    expect(Rake::Task['test_seeds:destroy']).to have_received(:execute)
  end

  it 'recreates the test seeds' do
    request
    expect(Rake::Task['test_seeds:create']).to have_received(:execute)
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
      request
      expect(Rake::Task['test_seeds:destroy']).not_to have_received(:execute)
    end

    it 'does not recreate test seeds' do
      request
      expect(Rake::Task['test_seeds:create']).not_to have_received(:execute)
    end
  end

  context 'when the RESEED_API_KEY is not set in the environment' do
    let(:headers) { { 'X-RESEED-API-KEY' => '' } }

    before do
      ENV.delete('RESEED_API_KEY')
    end

    it 'returns not found' do
      request
      expect(response).to be_not_found
    end

    it 'does not destroy test seeds' do
      request
      expect(Rake::Task['test_seeds:destroy']).not_to have_received(:execute)
    end

    it 'does not recreate test seeds' do
      request
      expect(Rake::Task['test_seeds:create']).not_to have_received(:execute)
    end
  end

  context 'when the X-RESEED_API_KEY is incorrect' do
    let(:headers) { { 'X-RESEED-API-KEY' => 'my_dodgy_api_key' } }

    it 'returns not found' do
      request
      expect(response).to be_not_found
    end

    it 'does not destroy test seeds' do
      request
      expect(Rake::Task['test_seeds:destroy']).not_to have_received(:execute)
    end

    it 'does not recreate test seeds' do
      request
      expect(Rake::Task['test_seeds:create']).not_to have_received(:execute)
    end
  end
end
