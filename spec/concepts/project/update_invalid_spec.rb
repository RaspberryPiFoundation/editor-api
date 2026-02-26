# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Update, type: :unit do
  subject(:update) do
    update_hash = {
      name: 'updated project name',
      components: [default_component_hash, edited_component_hash, new_component_hash]
    }
    described_class.call(project:, update_hash:, current_user:)
  end

  let(:current_user) { create(:user) }
  let!(:project) { create(:project, :with_default_component, :with_components, component_count: 2) }
  let(:editable_component) { project.components.last }
  let(:default_component) { project.components.first }

  let(:edited_component_hash) do
    {
      id: editable_component.id,
      name: nil,
      content: 'updated content',
      extension: 'py'
    }
  end

  describe '.call' do
    context 'when updated project component is invalid' do
      it 'returns failure? true' do
        expect(update.failure?).to be(true)
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
    component.attributes.symbolize_keys.slice(:name, :content, :extension)
  end

  def default_component_hash
    default_component.attributes.symbolize_keys.slice(
      :id,
      :name,
      :content,
      :extension
    )
  end

  def new_component_hash
    {
      name: 'new component',
      content: 'new component content',
      extension: 'py'
    }
  end
end
