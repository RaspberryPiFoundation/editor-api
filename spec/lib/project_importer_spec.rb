# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectImporter do
  let(:importer) do
    described_class.new(
      name: 'My amazing project',
      identifier: 'my-amazing-project',
      type: Project::Types::PYTHON,
      locale: 'ja-JP',
      components: [
        { name: 'main', extension: 'py', content: 'print(\'hello\')', default: true },
        { name: 'amazing', extension: 'py', content: 'print(\'this is amazing\')' }
      ],
      images: [
        { filename: 'my-amazing-image.png', io: File.open('spec/fixtures/files/test_image_1.png') }
      ],
      videos: [
        { filename: 'my-amazing-video.mp4', io: File.open('spec/fixtures/files/test_video_1.mp4') }
      ],
      audio: [
        { filename: 'my-amazing-audio.mp3', io: File.open('spec/fixtures/files/test_audio_1.mp3') }
      ]
    )
  end

  context 'when the project with correct locale does not already exist in the database' do
    let(:project) { Project.find_by(identifier: importer.identifier, user_id: nil, locale: importer.locale) }

    before do
      create(:project, identifier: importer.identifier, user_id: nil)
    end

    it 'saves the project to the database' do
      expect { importer.import! }.to change(Project, :count).by(1)
    end

    it 'names the project correctly' do
      importer.import!
      expect(project.name).to eq(importer.name)
    end

    it 'gives the project the correct type' do
      importer.import!
      expect(project.project_type).to eq(importer.type)
    end

    it 'creates the project components' do
      importer.import!
      expect(project.components.count).to eq(2)
    end

    it 'creates the project images' do
      importer.import!
      expect(project.images.count).to eq(1)
    end

    it 'creates the project videos' do
      importer.import!
      expect(project.videos.count).to eq(1)
    end

    it 'creates the project audio' do
      importer.import!
      expect(project.audio.count).to eq(1)
    end
  end

  context 'when the project already exists in the database' do
    let!(:project) do
      create(
        :project,
        :with_default_component,
        :with_components,
        :with_attached_image,
        :with_attached_video,
        :with_attached_audio,
        component_count: 2,
        identifier: 'my-amazing-project',
        locale: 'ja-JP'
      )
    end

    it 'does not change number of saved projects' do
      expect { importer.import! }.not_to change(Project, :count)
    end

    it 'renames project' do
      expect { importer.import! }.to change { project.reload.name }.to(importer.name)
    end

    it 'deletes removed components' do
      expect { importer.import! }.to change { project.components.count }.from(3).to(2)
    end

    it 'updates existing components' do
      expect { importer.import! }.to change { project.reload.components[0].content }.to('print(\'hello\')')
    end

    it 'creates new components' do
      expect { importer.import! }.to change { project.reload.components[1].name }.to('amazing')
    end

    it 'updates images' do
      expect { importer.import! }.to change { project.reload.images[0].filename.to_s }.to('my-amazing-image.png')
    end

    it 'updates videos' do
      expect { importer.import! }.to change { project.reload.videos[0].filename.to_s }.to('my-amazing-video.mp4')
    end

    it 'updates audio' do
      expect { importer.import! }.to change { project.reload.audio[0].filename.to_s }.to('my-amazing-audio.mp3')
    end
  end

  context 'when the project has type code_editor_scratch' do
    let(:scratch_project_file) { Tempfile.new(['test_scratch_project', '.sb3']) }
    let(:parser) { instance_double(Sb3Parser, parse: parser_result) }
    let(:parser_result) do
      {
        scratch_component: { content: JSON.parse(scratch_project_content.to_json) },
        assets: []
      }
    end
    let(:importer) do
      described_class.new(
        name: 'My amazing Scratch project',
        identifier: 'my-amazing-scratch-project',
        type: Project::Types::CODE_EDITOR_SCRATCH,
        locale: 'en',
        components: [
          { name: 'main', extension: 'sb3', file_path: scratch_project_file.path }
        ]
      )
    end
    let(:scratch_project_content) do
      {
        targets: [
          {
            costumes: [{ md5ext: 'test_image_1.png' }],
            sounds: [{ md5ext: 'test_audio_1.mp3' }],
            videos: [{ md5ext: 'test_video_1.mp4' }]
          }
        ]
      }
    end

    let(:project) { Project.find_by(identifier: importer.identifier, user_id: nil, locale: importer.locale) }

    before do
      allow(Sb3Parser).to receive(:new).and_return(parser)

      scratch_project_file.binmode
      scratch_project_file.write(
        sb3_archive(
          'project.json' => scratch_project_content.to_json,
          'test_image_1.png' => sb3_fixture_content('test_image_1.png'),
          'test_video_1.mp4' => sb3_fixture_content('test_video_1.mp4'),
          'test_audio_1.mp3' => sb3_fixture_content('test_audio_1.mp3')
        ).read
      )
      scratch_project_file.flush
    end

    after do
      scratch_project_file.close
      scratch_project_file.unlink
    end

    context 'when importing a new scratch project' do
      it 'imports the Scratch component content' do
        importer.import!

        expect(project.components.count).to eq(0)
        expect(project.scratch_component.content).to eq(JSON.parse(scratch_project_content.to_json))
      end

      it 'imports the project assets' do
        importer.import!
        expect(ScratchAsset.global_assets.where(filename: ['test_image_1.png', 'test_video_1.mp4', 'test_audio_1.mp3']).count).to eq(3)
      end

      it 'raises and rolls back the import when the scratch content cannot be parsed' do
        allow(parser).to receive(:parse).and_return({ scratch_component: { content: nil }, assets: [] })

        expect { importer.import! }
          .to raise_error(ProjectImporter::ImportError, 'Scratch project content could not be parsed')

        expect(Project.where(identifier: importer.identifier, locale: importer.locale).count).to eq(0)
      end
    end

    context 'when the scratch project already exists in the database' do
      let(:original_scratch_content) do
        { targets: ['old target'], monitors: [], extensions: [], meta: {} }
      end
      let!(:project) do
        create(
          :project,
          identifier: 'my-amazing-scratch-project',
          locale: 'en',
          project_type: Project::Types::CODE_EDITOR_SCRATCH,
          name: 'Old Scratch project name'
        )
      end

      before do
        create(:scratch_component, project:, content: original_scratch_content)
      end

      it 'does not create a new project' do
        expect { importer.import! }.not_to change(Project, :count)
      end

      it 'updates the project name' do
        expect { importer.import! }.to change { project.reload.name }.to(importer.name)
      end

      it 'updates the scratch component content' do
        importer.import!

        expect(project.reload.scratch_component.content).to eq(JSON.parse(scratch_project_content.to_json))
      end

      it 'imports any new assets without duplicating existing ones' do
        create(:scratch_asset, :with_file, filename: 'test_image_1.png')

        importer.import!

        expect(ScratchAsset.global_assets.where(filename: ['test_image_1.png', 'test_video_1.mp4', 'test_audio_1.mp3']).count).to eq(3)
      end

      it 'rolls back project changes when the scratch content cannot be parsed' do
        allow(parser).to receive(:parse).and_return({ scratch_component: { content: nil }, assets: [] })

        expect { importer.import! }
          .to raise_error(ProjectImporter::ImportError, 'Scratch project content could not be parsed')

        expect(project.reload.name).to eq('Old Scratch project name')
        expect(project.scratch_component.content).to eq(original_scratch_content.deep_stringify_keys)
      end
    end
  end
end
