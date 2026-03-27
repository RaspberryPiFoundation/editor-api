# frozen_string_literal: true

#
require 'rails_helper'
require 'scratch_asset_importer'

RSpec.describe ScratchAssetImporter do
  describe '.import' do
    it 'imports assets from the config' do
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read
      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)

      described_class.import(['123abc.png'], 'https://example.net/internalapi/asset/')

      scratch_asset = ScratchAsset.find_by(filename: '123abc.png')
      expect(scratch_asset).to be_present
      expect(scratch_asset.file.download).to eq(image)
    end

    it 'does nothing if asset already exists' do
      create(:scratch_asset, :with_file, filename: '123abc.png')

      expect do
        described_class.import(['123abc.png'], 'https://example.net/internalapi/asset/')
      end.not_to change(ScratchAsset, :count)
    end

    it 'can import multiple assets' do
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read

      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)
      stub_request(:get, 'https://example.net/internalapi/asset/456xyz.png/get/').to_return(status: 200, body: image)

      described_class.import(['123abc.png', '456xyz.png'], 'https://example.net/internalapi/asset/')
      expect(ScratchAsset.find_by(filename: '123abc.png')).to be_present
      expect(ScratchAsset.find_by(filename: '456xyz.png')).to be_present
    end

    it 'skips assets that fail to import' do
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read

      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 500, body: 'error')
      stub_request(:get, 'https://example.net/internalapi/asset/456xyz.png/get/').to_return(status: 200, body: image)

      described_class.import(['123abc.png', '456xyz.png'], 'https://example.net/internalapi/asset/')
      expect(ScratchAsset.find_by(filename: '123abc.png')).not_to be_present
      expect(ScratchAsset.find_by(filename: '456xyz.png')).to be_present
    end
  end
end
