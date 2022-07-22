# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::Create, type: :unit do
  subject(:create_project) { described_class.call(user_id: user_id, params: project_params) }

  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project_params) do
    {}
  end

  before do
    mock_phrase_generation
  end

  describe '.call' do
    it 'returns success' do
      expect(create_project.success?).to eq(true)
    end

    it 'creates a new project' do
      expect { create_project }.to change(Project, :count).by(1)
    end

    it 'assigns project to user' do
      created_project = create_project[:project]
      expect(created_project.user_id).to eq(user_id)
    end

    it 'returns project with single component' do
      components = create_project[:project].components
      expect(components.length).to eq(1)
    end

    it 'returns project with default main component' do
      component = create_project[:project].components.first
      attrs = component.attributes.symbolize_keys.slice(:name, :extension, :content, :default, :index)
      expected = { name: 'main', extension: 'py', content: nil, default: true, index: 0 }
      expect(attrs).to eq(expected)
    end

    context 'when initial project present' do
      subject(:create_project_with_content) { described_class.call(user_id: user_id, params: project_params) }

      let(:project_params) do
        {
          type: 'python',
          components: [
            {
              name: 'main',
              extension: 'py',
              content: 'print("hello world")',
              index: 0,
              default: true
            }
          ]
        }
      end

      it 'returns success' do
        expect(create_project_with_content.success?).to eq(true)
      end

      it 'returns project with correct component content' do
        new_project = create_project_with_content[:project]
        expect(new_project.components.first.content).to eq('print("hello world")')
      end
    end

    context 'when creation fails' do
      before do
        mock_project = instance_double(Project)
        allow(mock_project).to receive(:components).and_raise('Some error')
        allow(Project).to receive(:new).and_return(mock_project)
      end

      it 'returns failure' do
        expect(create_project.failure?).to eq(true)
      end

      it 'returns error message' do
        expect(create_project[:error]).to eq('Error creating project')
      end
    end
  end
end
