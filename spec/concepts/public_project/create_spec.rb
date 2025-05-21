# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicProject::Create, type: :unit do
  describe '.call' do
    subject(:create_project) { described_class.call(project_hash:) }

    let(:identifier) { 'foo-bar-baz' }
    let(:project_hash) do
      {
        identifier:,
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Foo bar baz'
      }
    end

    context 'with valid content' do
      it 'returns success' do
        expect(create_project.success?).to be(true)
      end

      it 'returns project with identifier' do
        new_project = create_project[:project]
        expect(new_project.identifier).to eq(identifier)
      end
    end

    context 'when creation fails' do
      before do
        mock_project = instance_double(Project)
        allow(mock_project).to receive(:save!).and_raise('Some error')
        allow(Project).to receive(:new).and_return(mock_project)
        allow(Sentry).to receive(:capture_exception)
      end

      it 'returns failure' do
        expect(create_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(create_project[:error]).to eq('Error creating project: Some error')
      end

      it 'sent the exception to Sentry' do
        create_project
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end
  end
end
