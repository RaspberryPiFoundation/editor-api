# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::Operation::CreateRemix, type: :unit do
  subject(:create_remix) { described_class.call(params, user_id) }

  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let!(:original_project) { create(:project, :with_components) }

  before do
    mock_phrase_generation
  end

  describe '.call' do
    context 'when all params valid' do
      let(:params) { { project_id: original_project.identifier } }

      it 'returns success' do
        result = create_remix
        expect(result.success?).to eq(true)
      end

      it 'creates new project' do
        expect { create_remix }.to change(Project, :count).by(1)
      end

      it 'assigns a new identifer to new project' do
        result = create_remix
        remixed_project = result[:project]
        expect(remixed_project.identifier).not_to eq(original_project.identifier)
      end

      it 'assigns user_id to new project' do
        remixed_project = create_remix[:project]
        expect(remixed_project.user_id).to eq(user_id)
      end

      it 'duplicates properties on new project' do
        remixed_project = create_remix[:project]

        remixed_attrs = remixed_project.attributes.symbolize_keys.slice(:name, :project_type)
        original_attrs = original_project.attributes.symbolize_keys.slice(:name, :project_type)
        expect(remixed_attrs).to eq(original_attrs)
      end

      it 'duplicates project components' do
        remixed_props_array = component_array_props(create_remix[:project].components)
        original_props_array = component_array_props(original_project.components)

        expect(remixed_props_array).to match_array(original_props_array)
      end
    end

    context 'when user_id is not present' do
      let(:user_id) { nil }
      let(:params) { { project_id: original_project.identifier } }

      it 'returns failure' do
        result = create_remix
        expect(result.failure?).to eq(true)
      end

      it 'does not create new project' do
        expect { create_remix }.not_to change(Project, :count)
      end
    end
  end

  def component_array_props(components)
    components.map do |x|
      {
        name: x.name,
        content: x.content,
        extension: x.extension,
        index: x.index
      }
    end
  end
end
