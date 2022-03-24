# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::Update, type: :unit do
  subject(:update) do
    params = {
      name: 'updated project name',
      components: [default_component_params, edited_component_params, new_component_params]
    }
    described_class.call(params: params, project: project)
  end

  let!(:project) { create(:project, :with_default_component, :with_components, component_count: 2) }
  let(:editable_component) { project.components.last }
  let(:default_component) { project.components.first }

  let(:edited_component_params) do
    {
      id: editable_component.id,
      name: nil,
      content: 'updated content',
      extension: 'py',
      index: 5
    }
  end

  describe '.call' do
    context 'when updated project component is invalid' do
      it 'returns failure? true' do
        expect(update.failure?).to eq(true)
      end

      it 'does not amend any project properties' do
        expect { update }.not_to change { project.reload.name }
      end

      it 'does not amend any component properties' do
        expect { update }.not_to change { component_properties_hash(editable_component.reload) }
      end

      it 'does not create or delete components' do
        expect { update }.not_to change(Component, :count)
      end
    end
  end

  def component_properties_hash(component)
    component.attributes.symbolize_keys.slice(:name, :content, :extension, :index)
  end

  def default_component_params
    default_component.attributes.symbolize_keys.slice(
      :id,
      :name,
      :content,
      :extension,
      :index
    )
  end

  def new_component_params
    {
      name: 'new component',
      content: 'new component content',
      extension: 'py',
      index: 99
    }
  end
end
