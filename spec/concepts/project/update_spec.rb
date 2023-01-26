# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Update, type: :unit do
  subject(:update) do
    update_hash = {
      name: 'updated project name',
      components: component_hash
    }
    described_class.call(project:, update_hash:)
  end

  let!(:project) { create(:project, :with_default_component, :with_components) }
  let(:editable_component) { project.components.last }
  let(:default_component) { project.components.first }

  describe '.call' do
    let(:edited_component_hash) do
      {
        id: editable_component.id,
        name: 'updated component name',
        content: 'updated content',
        extension: 'py',
        index: 5
      }
    end

    context 'when only amending components' do
      let(:component_hash) { [default_component_hash, edited_component_hash] }

      it 'returns success? true' do
        expect(update.success?).to be(true)
      end

      it 'updates project properties' do
        expect { update }.to change { project.reload.name }.to('updated project name')
      end

      it 'updates component properties' do
        expect { update }
          .to change { component_properties_hash(editable_component.reload) }
          .to(edited_component_hash.slice(:name, :content, :extension, :index))
      end
    end

    context 'when a new component has been added' do
      let(:component_hash) { [default_component_hash, edited_component_hash, new_component_hash] }

      it 'creates a new component' do
        expect { update }.to change(Component, :count).by(1)
      end

      it 'creates component with correct properties' do
        update
        created_component = project.components.find_by(**new_component_hash)
        expect(created_component).not_to be_nil
      end
    end

    context 'when a component has been removed' do
      let(:component_hash) { [default_component_hash] }

      it 'deletes a component' do
        expect { update }.to change(Component, :count).by(-1)
      end
    end

    context 'when no components have been specified' do
      let(:component_hash) { nil }

      it 'keeps the same number of components' do
        expect { update }.not_to change(Component, :count)
      end

      it 'updates project properties' do
        expect { update }.to change { project.reload.name }.to('updated project name')
      end
    end
  end

  def component_properties_hash(component)
    component.attributes.symbolize_keys.slice(
      :name,
      :content,
      :extension,
      :index
    )
  end

  def default_component_hash
    default_component.attributes.symbolize_keys.slice(
      :id,
      :name,
      :content,
      :extension,
      :index
    )
  end

  def new_component_hash
    {
      name: 'new component',
      content: 'new component content',
      extension: 'py',
      index: 99
    }
  end
end
