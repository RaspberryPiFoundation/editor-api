# frozen_string_literal: true

require 'rails_helper'
require 'sb3_parser'

RSpec.describe Sb3Parser do
  describe '#parse' do
    let(:png_content) { sb3_fixture_content('test_image_1.png') }
    let(:mp3_content) { sb3_fixture_content('test_audio_1.mp3') }
    let(:project_json) do
      {
        targets: [
          {
            costumes: [
              { name: 'cat', md5ext: 'abc123.png' },
              { name: 'duplicate cat', md5ext: 'abc123.png' }
            ],
            sounds: [
              { name: 'meow', md5ext: 'def456.mp3' }
            ]
          }
        ]
      }
    end
    let(:entries) do
      {
        'project.json' => project_json.to_json,
        'abc123.png' => png_content,
        'def456.mp3' => mp3_content
      }
    end

    it 'parses project.json and referenced assets from component io' do
      result = described_class.new(component: { io: sb3_archive(entries) }).parse

      expect(result.fetch(:scratch_component).fetch(:content)).to eq(JSON.parse(project_json.to_json))

      assets = result.fetch(:assets)
      expect(assets.map { |asset| asset.fetch(:filename) }).to contain_exactly('abc123.png', 'def456.mp3')

      png_asset = assets.find { |asset| asset.fetch(:filename) == 'abc123.png' }
      expect(png_asset.fetch(:content_type)).to eq('image/png')
      expect(png_asset.fetch(:io).read).to eq(png_content)
    end

    it 'parses an archive from a file path' do
      Tempfile.create(['scratch-project', '.sb3']) do |file|
        archive = sb3_archive(entries)
        file.binmode
        file.write(archive.read)
        file.flush

        result = described_class.new(file_path: file.path).parse

        expect(result.fetch(:scratch_component).fetch(:content)).to eq(JSON.parse(project_json.to_json))
        expect(result.fetch(:assets).map { |asset| asset.fetch(:filename) }).to contain_exactly('abc123.png', 'def456.mp3')
      end
    end

    it 'returns no assets when project.json does not reference any md5ext values' do
      archive = sb3_archive('project.json' => { targets: [] }.to_json)

      result = described_class.new(component: { io: archive }).parse

      expect(result.fetch(:assets)).to eq([])
    end

    it 'raises when project.json is missing' do
      archive = sb3_archive('abc123.png' => png_content)

      expect do
        described_class.new(component: { io: archive }).parse
      end.to raise_error(described_class::MissingProjectJsonError, 'project.json not found in SB3 archive')
    end

    it 'raises when a referenced asset is missing' do
      archive = sb3_archive('project.json' => { targets: [{ costumes: [{ md5ext: 'missing.png' }] }] }.to_json)

      expect do
        described_class.new(component: { io: archive }).parse
      end.to raise_error(described_class::MissingAssetError, 'asset missing.png not found in SB3 archive')
    end
  end
end
