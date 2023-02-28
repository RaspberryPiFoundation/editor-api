# frozen_string_literal: true

require 'rails_helper'
require 'project_importer'

RSpec.describe ProjectImporter do
  let(:importer) do
    described_class.new(
      name: 'My amazing project',
      identifier: 'my-amazing-project',
      type: 'python',
      components: [
        { name: 'main', extension: 'py', content: 'print(\'hello\')', default: true },
        { name: 'amazing', extension: 'py', content: 'print(\'this is amazing\')' }
      ],
      images: [
        { filename: 'my-amazing-image.png', io: File.open('spec/fixtures/files/test_image_1.png') }
      ]
    )
  end

  context 'when the project does not already exist in the database' do
    let(:project) { Project.find_by(identifier: importer.identifier) }

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
  end

  context 'when the project already exists in the database' do
    let!(:project) do
      create(
        :project,
        :with_default_component,
        :with_components,
        :with_attached_image,
        component_count: 2,
        identifier: 'my-amazing-project'
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
  end
end
