# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestUtilitiesController do
  let(:headers) { { 'X-RESEED-API-KEY' => ENV.fetch('RESEED_API_KEY', nil) } }

  before do
    host! 'test-editor-api.raspberrypi.org'
    ENV['RESEED_API_KEY'] = 'my_test_api_key'
  end

  after do
    ENV.delete('RESEED_API_KEY')
  end

  describe 'POST /test/reseed' do
    subject(:request) { post('/test/reseed', headers:) }

    before do
      allow(Rake::Task['test_seeds:destroy']).to receive(:execute)
      allow(Rake::Task['test_seeds:create']).to receive(:execute)
    end

    around do |example|
      DatabaseCleaner.clean_with(:truncation)
      DatabaseCleaner.strategy = :transaction

      DatabaseCleaner.cleaning do
        Rake::Task.tasks.each(&:reenable)
        example.run
      ensure
        Rake::Task.tasks.each(&:reenable)
      end
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

  describe 'feature toggle endpoints' do
    let(:school) { create(:school) }
    let(:feature_key) { :flipper_feature }
    let(:params) do
      {
        feature_key:
      }
    end

    shared_examples 'a rejected feature toggle request' do
      it 'returns not found' do
        request
        expect(response).to be_not_found
      end

      it 'does not change the feature' do
        expect { request }.not_to(change { Flipper.enabled?(feature_key, school) })
      end
    end

    shared_examples 'a feature toggle endpoint' do
      it 'returns no content' do
        request
        expect(response).to be_no_content
      end

      context 'when the feature_key param is missing' do
        let(:params) { {} }

        it 'returns bad request' do
          request
          expect(response).to be_bad_request
        end

        it 'does not change the feature' do
          expect { request }.not_to(change { Flipper.enabled?(feature_key, school) })
        end
      end

      context 'when the host is not allowed' do
        before { host! 'editor-api.raspberrypi.org' }

        it_behaves_like 'a rejected feature toggle request'
      end

      context 'when the RESEED_API_KEY is not set in the environment' do
        let(:headers) { { 'X-RESEED-API-KEY' => '' } }

        before { ENV.delete('RESEED_API_KEY') }

        it_behaves_like 'a rejected feature toggle request'
      end

      context 'when the X-RESEED-API-KEY is incorrect' do
        let(:headers) { { 'X-RESEED-API-KEY' => 'my_dodgy_api_key' } }

        it_behaves_like 'a rejected feature toggle request'
      end
    end

    describe 'POST /test/enable_feature' do
      subject(:request) { post('/test/enable_feature', headers:, params:) }

      before do
        Flipper.disable(feature_key)
      end

      it 'universally enables the feature' do
        expect { request }.to change { Flipper.enabled?(feature_key, school) }.from(false).to(true)
      end

      it_behaves_like 'a feature toggle endpoint'
    end

    describe 'POST /test/disable_feature' do
      subject(:request) { post('/test/disable_feature', headers:, params:) }

      before do
        Flipper.enable_actor(feature_key, school)
      end

      it 'universally disables the feature' do
        expect { request }.to change { Flipper.enabled?(feature_key, school) }.from(true).to(false)
      end

      it_behaves_like 'a feature toggle endpoint'
    end
  end
end
