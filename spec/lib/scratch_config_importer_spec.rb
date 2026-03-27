# frozen_string_literal: true

#
require 'rails_helper'
require 'scratch_asset_importer'

RSpec.describe ScratchConfigImporter do
  before do
    allow(ScratchAssetImporter).to receive(:import)
  end

  describe '.import' do
    it 'imports assets from the config' do
      config = [{ md5ext: '123abc.png' }].to_json
      stub_request(:get, 'https://example.com/config/backdrops.json').to_return(status: 200, body: config)

      described_class.import('https://example.com/config/backdrops.json', 'https://example.net/internalapi/asset/')

      expect(ScratchAssetImporter).to have_received(:import).with(['123abc.png'], 'https://example.net/internalapi/asset/')
    end

    it 'handles assets nested under sounds and costumes' do
      config = [
        {
          costumes: [{
            md5ext: '123abc.png'
          }],
          sounds: [{
            md5ext: '456xyz.png'
          }]
        }
      ].to_json
      stub_request(:get, 'https://example.com/config/sprites.json').to_return(status: 200, body: config)

      described_class.import('https://example.com/config/sprites.json', 'https://example.net/internalapi/asset/')

      expect(ScratchAssetImporter).to have_received(:import).with(['123abc.png', '456xyz.png'], 'https://example.net/internalapi/asset/')
    end
  end
end
