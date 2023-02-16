# frozen_string_literal: true

require 'rails_helper'
require 'project_importer'

Rails.application.load_tasks

describe 'projects:create_starter', type: :task do
  subject { task.execute }

  let(:project_config) { { 'NAME' => 'My amazing project', 'IDENTIFIER' => 'my-amazing-project', 'TYPE' => 'python' } }

  it 'runs' do
    allow(YAML).to receive(:safe_load).and_return(project_config)
    allow(File).to receive(:read).and_return('print("hello")')
    expect { Rake::Task['projects:create_starter'].invoke }.not_to raise_error
  end

  it 'calls the ProjectImporter' do
    expected_config = { components: [], identifier: 'my-amazing-project', images: [], name: 'My amazing project', type: 'python' }

    allow(ProjectImporter).to receive(:new)
    ProjectImporter.new(name: project_config['NAME'], identifier: project_config['IDENTIFIER'],
                        type: project_config['TYPE'] ||= 'python', components: [], images: [])
    expect(ProjectImporter).to have_received(:new).with(expected_config)
  end
end
