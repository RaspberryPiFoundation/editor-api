# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::Update, type: :unit do
  subject(:update) { described_class.call(project_params, project) }

  let!(:project) { create(:project, :with_default_component) }
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
    context 'when default file is removed' do
      let(:project_params) do
        {
          name: 'updated project name',
          components: []
        }
      end

      it 'returns failure? true' do
        expect(update.failure?).to eq(true)
      end

      it 'does not delete the default component' do
        expect { update }.not_to change(Component, :count)
      end
    end

    context 'when default file name is changed' do
      it 'does not update file name'
    end
  end

  def component_properties_hash(component)
    component.attributes.symbolize_keys.slice(:name, :content, :extension, :index)
  end
end
