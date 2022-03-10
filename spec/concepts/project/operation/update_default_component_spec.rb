# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::Update, type: :unit do
  subject(:update) { described_class.call(project_params, project) }

  let!(:project) { create(:project, :with_default_component) }
  let(:default_component) { project.components.first }

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

      it 'returns error message' do
        expect(update[:error]).to eq(I18n.t('errors.project.editing.delete_default_component'))
      end

      it 'does not delete the default component' do
        expect { update }.not_to change(Component, :count)
      end

      it 'does not update project' do
        expect { update }.not_to change { project.reload.name }
      end
    end

    context 'when default file properties are changed' do
      let(:default_component_params) do
        default_component.attributes.symbolize_keys.slice(
          :id,
          :name,
          :content,
          :extension,
          :index
        )
      end

      let(:project_params) do
        {
          name: 'updated project name',
          components: [default_component_params]
        }
      end

      it 'does not update file name' do
        default_component_params[:name] = 'Updated name'
        expect { update }.not_to change { default_component.reload.name }
      end

      it 'does not update file extension' do
        default_component_params[:extension] = 'txt'
        expect { update }.not_to change { default_component.reload.extension }
      end

      it 'does not update project' do
        default_component_params[:name] = 'Updated name'
        expect { update }.not_to change { project.reload.name }
      end
    end
  end
end
