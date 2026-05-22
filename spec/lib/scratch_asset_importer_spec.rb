# frozen_string_literal: true

require 'rails_helper'
require 'scratch_asset_importer'

RSpec.describe ScratchAssetImporter do
  describe '.import_all' do
    it 'imports assets from the config' do
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read
      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)

      described_class.import_all(['123abc.png'], 'https://example.net/internalapi/asset/')

      scratch_asset = ScratchAsset.find_by(filename: '123abc.png')
      expect(scratch_asset).to be_present
      expect(scratch_asset).to be_global
      expect(scratch_asset.file.download).to eq(image)
    end

    it 'does nothing if asset already exists' do
      create(:scratch_asset, :with_file, filename: '123abc.png')

      expect do
        described_class.import_all(['123abc.png'], 'https://example.net/internalapi/asset/')
      end.not_to change(ScratchAsset, :count)
    end

    it 'can import multiple assets' do
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read

      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)
      stub_request(:get, 'https://example.net/internalapi/asset/456xyz.png/get/').to_return(status: 200, body: image)

      described_class.import_all(['123abc.png', '456xyz.png'], 'https://example.net/internalapi/asset/')
      expect(ScratchAsset.find_by(filename: '123abc.png')).to be_present
      expect(ScratchAsset.find_by(filename: '456xyz.png')).to be_present
    end

    it 'still imports a global asset when a project asset already uses the filename' do
      project = create(:project, project_type: Project::Types::CODE_EDITOR_SCRATCH, locale: nil, user_id: SecureRandom.uuid)
      create(:scratch_component, project:)
      create(:scratch_asset, :with_file, filename: '123abc.png', project:)
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read

      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)

      expect do
        described_class.import_all(['123abc.png'], 'https://example.net/internalapi/asset/')
      end.to change { ScratchAsset.global_assets.where(filename: '123abc.png').count }.by(1)
    end

    it 'skips assets that fail to import' do
      image = Rails.root.join('spec/fixtures/files/test_image_1.png').read

      stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 500, body: 'error')
      stub_request(:get, 'https://example.net/internalapi/asset/456xyz.png/get/').to_return(status: 200, body: image)

      described_class.import_all(['123abc.png', '456xyz.png'], 'https://example.net/internalapi/asset/')
      expect(ScratchAsset.find_by(filename: '123abc.png')).not_to be_present
      expect(ScratchAsset.find_by(filename: '456xyz.png')).to be_present
    end

    describe 'syncing to editor asset bucket' do
      let(:s3_client) { instance_double(Aws::S3::Client) }

      around do |example|
        editor_asset_env_vars = {
          EDITOR_ASSETS_BUCKET: 'test-bucket',
          EDITOR_ASSETS_ACCESS_KEY_ID: 'test-access-key-id',
          EDITOR_ASSETS_SECRET_ACCESS_KEY: 'test-secret-access-key',
          EDITOR_ASSETS_ENDPOINT: 'https://r2.example.com'
        }
        ClimateControl.modify(editor_asset_env_vars) do
          example.run
        end
      end

      before do
        allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
        allow(s3_client).to receive(:head_object).and_raise(Aws::S3::Errors::NotFound.new(nil, nil))
        allow(s3_client).to receive(:put_object)
      end

      it 'saves asset to editor asset bucket if it does not exist' do
        image = Rails.root.join('spec/fixtures/files/test_image_1.png').read
        stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)

        described_class.import_all(['123abc.png'], 'https://example.net/internalapi/asset/')

        expect(s3_client).to have_received(:put_object).with(
          bucket: 'test-bucket',
          key: 'internalapi/asset/123abc.png/get/',
          body: instance_of(StringIO),
          content_type: 'image/png',
          cache_control: 'public, max-age=604800'
        )
      end

      it 'does not save asset to editor asset bucket if it already exists' do
        image = Rails.root.join('spec/fixtures/files/test_image_1.png').read
        stub_request(:get, 'https://example.net/internalapi/asset/123abc.png/get/').to_return(status: 200, body: image)

        allow(s3_client).to receive(:head_object).with(bucket: 'test-bucket', key: 'internalapi/asset/123abc.png/get/').and_return(true)

        described_class.import_all(['123abc.png'], 'https://example.net/internalapi/asset/')
        expect(s3_client).not_to have_received(:put_object)
      end
    end
  end
end
