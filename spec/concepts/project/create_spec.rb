# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Create, type: :unit do
  subject(:create_project) { described_class.call(project_hash:) }

  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }

  before do
    mock_phrase_generation
    ActionController::Parameters.permit_all_parameters = true
  end

  describe '.call' do
    let(:project_hash) { ActionController::Parameters.new({}).merge(user_id:) }

    context 'with valid content' do
      subject(:create_project_with_content) { described_class.call(project_hash:) }

      let(:project_hash) {{
                                           project_type: 'python',
                                           components: [{
                                             name: 'main',
                                             extension: 'py',
                                             content: 'print("hello world")',
                                             index: 0,
                                             default: true
                                           }],
                                           image_list: [],
                                           user_id:
      }}

      it 'returns success' do
        expect(create_project_with_content.success?).to be(true)
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
        allow(Sentry).to receive(:capture_exception)
      end

      it 'returns failure' do
        expect(create_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(create_project[:error]).to eq('Error creating project')
      end

      it 'sent the exception to Sentry' do
        create_project
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end
  end
end
