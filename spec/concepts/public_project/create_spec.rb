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
      let(:project_hash) { {} }

      before do
        allow(Sentry).to receive(:capture_exception)
      end

      it 'returns failure' do
        expect(create_project.failure?).to be(true)
      end

      it 'sent the exception to Sentry' do
        create_project
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'when identifier is blank' do
      let(:identifier) { nil }

      it 'returns failure' do
        expect(create_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(create_project[:error]).to eq("Error creating project: Validation failed: Identifier can't be blank")
      end
    end

    context 'when identifier is in invalid format' do
      let(:identifier) { 'FooBarBaz' }

      it 'returns failure' do
        expect(create_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(create_project[:error]).to eq('Error creating project: Validation failed: Identifier is invalid')
      end
    end
  end
end
