# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Update, type: :unit do
  subject(:update) do
    update_hash = {
      name: 'updated project name',
      components: component_hash,
      instructions:
    }
    described_class.call(project:, update_hash:, current_user: )
  end

  let(:current_user) { create(:user) }
  let!(:project) { create(:project, :with_default_component, :with_components, :with_instructions) }
  let(:editable_component) { project.components.last }
  let(:default_component) { project.components.first }
  let(:component_hash) { project.components.map { |component| hash(component) } }
  let(:instructions) { project.instructions }

  describe '.call' do
    let(:edited_component_hash) do
      {
        id: editable_component.id,
        name: 'updated component name',
        content: 'updated content',
        extension: 'py'
      }
    end

    context 'when updating the instructions' do
      let(:instructions) { 'new instructions' }

      it 'returns success? true' do
        expect(update.success?).to be(true)
      end

      it 'updates project instructions' do
        expect { update }.to change { project.reload.instructions }.to('new instructions')
      end
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
          .to(edited_component_hash.slice(:name, :content, :extension))
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

    context 'when the instructions have changed and the current user is a student' do
      let(:school) { create(:school) }
      let!(:current_user) { create(:student, school:) }
      let!(:project) { create(:project, :with_instructions, school: school, user_id: current_user.id) }
      let(:instructions) { 'new instructions' }

      it 'returns success? false' do
        expect(update.success?).to be(false)
      end

      it 'does not update project name' do
        expect { update }.not_to change { project.reload.name }
      end

      it 'does not update project instructions' do
        expect { update }.not_to change { project.reload.instructions }
      end

      it 'returns an error message' do
        expect(update[:error]).to eq("Student cannot update project instructions")
      end
    end
  end

  def component_properties_hash(component)
    component.attributes.symbolize_keys.slice(
      :name,
      :content,
      :extension
    )
  end

  def hash(component)
    component.attributes.symbolize_keys.slice(
      :id,
      :name,
      :content,
      :extension
    )
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
