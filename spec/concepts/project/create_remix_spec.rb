# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project::CreateRemix, type: :unit do
  subject(:create_remix) { described_class.call(params: remix_params, user_id:, original_project:, remix_origin:) }

  let(:remix_origin) { 'editor.com' }
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let!(:original_project) { create(:project, :with_components, :with_attached_image, :with_attached_video, :with_attached_audio) }
  let(:remix_params) do
    component = original_project.components.first
    {
      name: 'My remixed project',
      identifier: original_project.identifier,
      components: [
        {
          id: component.id,
          name: component.name,
          extension: component.extension,
          content: 'some updated component content'
        }
      ],
      image_list: original_project.images.map do |image|
        {
          filename: image.filename.to_s
      }
    end
    }
  end

  before do
    mock_phrase_generation
  end

  describe '.call' do
    let(:params) { { project_id: original_project.identifier } }

    it 'returns success' do
      result = create_remix
      expect(result.success?).to be(true)
    end

    it 'creates new project' do
      expect { create_remix }.to change(Project, :count).by(1)
    end

    it 'assigns a new identifer to new project' do
      result = create_remix
      remixed_project = result[:project]
      expect(remixed_project.identifier).not_to eq(original_project.identifier)
    end

    it 'sets new project locale to nil' do
      remixed_project = create_remix[:project]
      expect(remixed_project.locale).to be_nil
    end

    it 'renames the project' do
      remixed_project = create_remix[:project]
      expect(remixed_project.name).to eq('My remixed project')
    end

    it 'assigns user_id to new project' do
      remixed_project = create_remix[:project]
      expect(remixed_project.user_id).to eq(user_id)
    end

    it 'duplicates properties on new project' do
      remixed_project = create_remix[:project]

      remixed_attrs = remixed_project.attributes.symbolize_keys.slice(:project_type)
      original_attrs = original_project.attributes.symbolize_keys.slice(:project_type)
      expect(remixed_attrs).to eq(original_attrs)
    end

    it 'sets remix origin' do
      remixed_project = create_remix[:project]
      expect(remixed_project.remix_origin).to eq(remix_origin)
    end

    it 'links remix to attached images' do
      remixed_project = create_remix[:project]
      expect(remixed_project.images.length).to eq(original_project.images.length)
    end

    it 'links remix to attached videos' do
      remixed_project = create_remix[:project]
      expect(remixed_project.videos.length).to eq(original_project.videos.length)
    end

    it 'links remix to attached audio' do
      remixed_project = create_remix[:project]
      expect(remixed_project.audio.length).to eq(original_project.audio.length)
    end

    it 'creates new attachments' do
      expect { create_remix }.to change(ActiveStorage::Attachment, :count).by(3)
    end

    it 'does not create new media' do
      expect { create_remix }.not_to change(ActiveStorage::Blob, :count)
    end

    it 'does not copy the lesson id' do
      remixed_project = create_remix[:project]
      expect(remixed_project.lesson_id).to be_nil
    end

    it 'creates new components' do
      expect { create_remix }.to change(Component, :count).by(1)
    end

    it 'persists changes made to submitted components' do
      remixed_project = create_remix[:project]
      expect(remixed_project.components.first.content).to eq('some updated component content')
    end

    context 'when a new component has been added before remixing' do
      let(:new_component_params) { { name: 'added_component', extension: 'py', content: 'some added component content' } }

      before do
        remix_params[:components] << new_component_params
      end

      it 'creates all components' do
        expect { create_remix }.to change(Component, :count).by(2)
      end

      it 'persists the new component' do
        remixed_project = create_remix[:project]
        new_component = remixed_project.components.find { |c| c.name == new_component_params[:name] }
        expect(new_component.attributes.symbolize_keys).to include(new_component_params)
      end
    end

    context 'when user_id is not present' do
      let(:user_id) { nil }
      let(:params) { { project_id: original_project.identifier } }

      it 'returns failure' do
        result = create_remix
        expect(result.failure?).to be(true)
      end

      it 'returns error message' do
        result = create_remix
        expect(result[:error]).to eq(I18n.t('errors.project.remixing.invalid_params'))
      end

      it 'does not create new project' do
        expect { create_remix }.not_to change(Project, :count)
      end
    end

    context 'when original project is not present' do
      subject(:create_remix) { described_class.call(params: remix_params, user_id:, original_project: nil, remix_origin:) }

      it 'returns failure' do
        result = create_remix
        expect(result.failure?).to be(true)
      end

      it 'returns error message' do
        result = create_remix
        expect(result[:error]).to eq(I18n.t('errors.project.remixing.invalid_params'))
      end

      it 'does not create new project' do
        expect { create_remix }.not_to change(Project, :count)
      end
    end

    context 'when project components are invalid' do
      let(:invalid_component_params) { { name: 'added_component', content: '' } }

      before do
        remix_params[:components] << invalid_component_params
      end

      it 'returns failure' do
        expect(create_remix.failure?).to be(true)
      end

      it 'sets error message' do
        expect(create_remix[:error]).to eq(I18n.t('errors.project.remixing.cannot_save'))
      end
    end
  end

  def component_props(component)
    {
      name: component.name,
      content: component.content,
      extension: component.extension
    }
  end
end
