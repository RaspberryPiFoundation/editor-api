# frozen_string_literal: true

require 'rails_helper'
require 'scratch_sb3_asset_importer'

RSpec.describe ScratchSb3AssetImporter do
  describe '.import_all' do
    def sb3_asset(filename, content = sb3_fixture_content(filename))
      { filename:, io: StringIO.new(content) }
    end

    it 'imports assets from SB3 archive content' do
      png_content = sb3_fixture_content('test_image_1.png')

      described_class.import_all([sb3_asset('test_image_1.png', png_content)])

      scratch_asset = ScratchAsset.find_by(filename: 'test_image_1.png')
      expect(scratch_asset).to be_present
      expect(scratch_asset).to be_global
      expect(scratch_asset.file.download).to eq(png_content)
    end

    it 'does nothing if global asset already exists' do
      create(:scratch_asset, :with_file, filename: 'test_image_1.png')

      expect do
        described_class.import_all([sb3_asset('test_image_1.png')])
      end.not_to change(ScratchAsset, :count)
    end

    it 'can import multiple assets' do
      described_class.import_all([
                                   sb3_asset('test_image_1.png'),
                                   sb3_asset('test_audio_1.mp3', sb3_fixture_content('test_audio_1.mp3'))
                                 ])

      expect(ScratchAsset.find_by(filename: 'test_image_1.png')).to be_present
      expect(ScratchAsset.find_by(filename: 'test_audio_1.mp3')).to be_present
    end

    it 'still imports a global asset when a project asset already uses the filename' do
      project = create(:project, project_type: Project::Types::CODE_EDITOR_SCRATCH, locale: nil, user_id: SecureRandom.uuid)
      create(:scratch_component, project:)
      create(:scratch_asset, :with_file, filename: 'test_image_1.png', project:)

      expect do
        described_class.import_all([sb3_asset('test_image_1.png')])
      end.to change { ScratchAsset.global_assets.where(filename: 'test_image_1.png').count }.by(1)
    end

    it 'skips assets that fail to import' do
      allow(ScratchAsset).to receive(:create!).and_call_original
      allow(ScratchAsset).to receive(:create!).with(filename: 'failing.png', project_id: nil, uploaded_user_id: nil)

      described_class.import_all([
                                   sb3_asset('failing.png', 'bad'),
                                   sb3_asset('test_image_1.png')
                                 ])

      expect(ScratchAsset.find_by(filename: 'failing.png')).not_to be_present
      expect(ScratchAsset.find_by(filename: 'test_image_1.png')).to be_present
    end
  end
end
