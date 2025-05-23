# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicProject::Update, type: :unit do
  describe '.call' do
    subject(:update_project) { described_class.call(project:, update_hash:) }

    let(:identifier) { 'foo-bar-baz' }
    let(:new_identifier) { 'new-identifier' }
    let(:new_name) { 'New name' }
    let!(:project) { create(:project, identifier:) }
    let(:update_hash) { { identifier: new_identifier, name: new_name } }

    context 'with valid content' do
      it 'returns success' do
        expect(update_project.success?).to be(true)
      end

      it 'returns project with new identifier' do
        updated_project = update_project[:project]
        expect(updated_project.identifier).to eq(new_identifier)
      end

      it 'returns project with new name' do
        updated_project = update_project[:project]
        expect(updated_project.name).to eq(new_name)
      end
    end

    context 'when update fails' do
      before do
        allow(project).to receive(:save!).and_raise('Some error')
        allow(Sentry).to receive(:capture_exception)
      end

      it 'returns failure' do
        expect(update_project.failure?).to be(true)
      end

      it 'sent the exception to Sentry' do
        update_project
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'when identifier is blank' do
      let(:new_identifier) { nil }

      it 'returns failure' do
        expect(update_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(update_project[:error]).to eq("Error updating project: Validation failed: Identifier can't be blank")
      end
    end

    context 'when identifier is in invalid format' do
      let(:new_identifier) { 'FooBarBaz' }

      it 'returns failure' do
        expect(update_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(update_project[:error]).to eq('Error updating project: Validation failed: Identifier is invalid')
      end
    end

    context 'when name is blank' do
      let(:new_name) { '' }

      it 'returns failure' do
        expect(update_project.failure?).to be(true)
      end

      it 'returns error message' do
        expect(update_project[:error]).to eq("Error updating project: Validation failed: Name can't be blank")
      end
    end
  end
end
