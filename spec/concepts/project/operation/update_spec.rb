# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::Update, type: :unit do
  subject(:update) { described_class.call(project_params, project) }

  let!(:project) { create(:project, :with_default_component, :with_components) }
  let(:editable_component) { project.components.last }
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

  let(:edited_component_params) do
    {
      id: editable_component.id,
      name: 'updated component name',
      content: 'updated content',
      extension: 'py',
      index: 5
    }
  end

  let(:new_component_params) do
    {
      name: 'new component',
      content: 'new component content',
      extension: 'py',
      index: 99
    }
  end

  describe '.call' do
    let(:project_params) do
      {
        name: 'updated project name',
        components: [default_component_params, edited_component_params]
      }
    end

    it 'returns success? true' do
      expect(update.success?).to eq(true)
    end

    it 'updates project properties' do
      expect { update }.to change(project, :name).to('updated project name')
    end

    it 'updates component properties' do
      expect { update }
        .to change { component_properties_hash(editable_component.reload) }
        .to(edited_component_params.slice(:name, :content, :extension, :index))
    end

    context 'when a new component has been added' do
      let(:project_params) do
        {
          name: 'updated project name',
          components: [
            default_component_params,
            edited_component_params,
            new_component_params
          ]
        }
      end

      it 'creates a new component' do
        expect { update }.to change(Component, :count).by(1)
      end

      it 'creates component with correct properties' do
        update
        created_component = project.components.find_by(**new_component_params)
        expect(created_component).not_to eq(nil)
      end
    end

    context 'when default file is removed' do
      it 'does not delete the component'
    end

    context 'when default file name is changed' do
      it 'does not update file name'
    end

    context 'when updated project is invalid' do
      it 'returns failure? true'
      it 'does not amend any project properties'
      it 'does not amend any component properties'
      it 'does not create new components'
      it 'does not delete removed components'
    end
  end

  def component_properties_hash(component)
    component.attributes.symbolize_keys.slice(:name, :content, :extension, :index)
  end
end
