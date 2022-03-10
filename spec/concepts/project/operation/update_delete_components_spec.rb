# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::Update, type: :unit do
  subject(:update) { described_class.call(project_params, project) }

  let!(:project) { create(:project, :with_default_component, :with_components) }
  let(:component_to_delete) { project.components.last }
  let(:default_component) { project.components.first }

  let(:default_component_params) do
    default_component.attributes.symbolize_keys.slice(
      :id,
      :name,
      :content,
      :extension,
      :index
    )
  end

  describe '.call' do
    context 'when an existing component has been removed' do
      let(:project_params) do
        {
          name: 'updated project name',
          components: [default_component_params]
        }
      end

      it 'deletes a component' do
        expect { update }.to change(Component, :count).by(-1)
      end

      it 'deletes the correct component' do
        update
        expect(Component.find_by(id: component_to_delete.id)).to eq(nil)
      end
    end
  end
end
