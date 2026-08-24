# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Update, type: :unit do
  subject(:update) { described_class.call(project:, update_hash:) }

  let!(:project) { create(:project, :with_default_component, :with_components) }
  let(:component_to_delete) { project.components.last }
  let(:default_component) { project.components.first }

  let(:default_component_hash) do
    default_component.attributes.symbolize_keys.slice(
      :id,
      :name,
      :content,
      :extension
    )
  end

  describe '.call' do
    context 'when an existing component has been removed' do
      let(:update_hash) do
        {
          name: 'updated project name',
          components: [default_component_hash]
        }
      end

      it 'deletes a component' do
        expect { update }.to change(Component, :count).by(-1)
      end

      it 'deletes the correct component' do
        update
        expect(Component.find_by(id: component_to_delete.id)).to be_nil
      end
    end
  end
end
