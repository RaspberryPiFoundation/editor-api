# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks

describe 'projects:create_starter', type: :task do
  subject { task.execute }

  let(:project_config) { { 'NAME' => 'My amazing project', 'IDENTIFIER' => 'my-amazing-project', 'TYPE' => 'python' } }

  it 'runs' do
    allow(YAML).to receive(:safe_load).and_return(project_config)
    allow(File).to receive(:read).and_return('print("hello")')
    expect { Rake::Task['projects:create_starter'].invoke }.not_to raise_error
  end
end
