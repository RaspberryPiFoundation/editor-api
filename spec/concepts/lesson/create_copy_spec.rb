# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::CreateCopy, type: :unit do
  let(:teacher_id) { SecureRandom.uuid }

  let!(:lesson) do
    create(:lesson, :with_project_components, :with_project_image, name: 'Test Lesson', description: 'Description', user_id: teacher_id)
  end

  let(:lesson_params) do
    { user_id: teacher_id }
  end

  it 'returns a successful operation response' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response.success?).to be(true)
  end

  it 'creates a lesson' do
    expect { described_class.call(lesson:, lesson_params:) }.to change(Lesson, :count).by(1)
  end

  it 'returns the new lesson in the operation response' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson]).to be_a(Lesson)
  end

  it 'assigns the parent' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].parent).to eq(lesson)
  end

  it 'assigns the name from the parent lesson' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].name).to eq('Test Lesson')
  end

  it 'assigns the description from the parent lesson' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].description).to eq('Description')
  end

  it 'can specify the name of the new copy' do
    new_params = lesson_params.merge(name: 'New Name')
    response = described_class.call(lesson:, lesson_params: new_params)
    expect(response[:lesson].name).to eq('New Name')
  end

  it 'can specify the description of the new copy' do
    new_params = lesson_params.merge(description: 'New Description')
    response = described_class.call(lesson:, lesson_params: new_params)
    expect(response[:lesson].description).to eq('New Description')
  end

  it 'creates a new project' do
    expect { described_class.call(lesson:, lesson_params:) }.to change(Project, :count).by(1)
  end

  it 'changes the project identifier' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].project.identifier).not_to eq(lesson.project.identifier)
  end

  it 'generates a new project identifier' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].project.identifier).to be_present
  end

  it 'gives the project the correct name' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].project.name).to eq(lesson.project.name)
  end

  it 'gives the project the correct user_id' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].project.user_id).to eq(teacher_id)
  end

  it 'gives the project the correct lesson_id' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].project.lesson_id).to eq(response[:lesson].id)
  end

  it 'copies the images from the parent project' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].project.images.length).to eq(lesson.project.images.length)
  end

  it 'copies the components from the parent project with the correct name' do
    original_component = lesson.project.components.first
    response = described_class.call(lesson:, lesson_params:)
    copied_component = response[:lesson].project.components.first
    expect(copied_component.name).to eq(original_component.name)
  end

  it 'copies the components from the parent project with the correct extension' do
    original_component = lesson.project.components.first
    response = described_class.call(lesson:, lesson_params:)
    copied_component = response[:lesson].project.components.first
    expect(copied_component.extension).to eq(original_component.extension)
  end

  it 'copies the components from the parent project with the correct content' do
    original_component = lesson.project.components.first
    response = described_class.call(lesson:, lesson_params:)
    copied_component = response[:lesson].project.components.first
    expect(copied_component.content).to eq(original_component.content)
  end

  context 'when the project is a Scratch project' do
    let(:copied_teacher_id) { SecureRandom.uuid }
    let(:lesson_params) { { user_id: copied_teacher_id } }
    let(:scratch_content) do
      {
        targets: [
          {
            isStage: true,
            costumes: [
              {
                assetId: 'teacher_asset',
                md5ext: 'teacher_asset.png',
                dataFormat: 'png'
              }
            ]
          }
        ],
        monitors: [],
        extensions: [],
        meta: {}
      }
    end

    before do
      lesson.project.update!(project_type: Project::Types::CODE_EDITOR_SCRATCH, locale: nil)
      create(:scratch_component, project: lesson.project, content: scratch_content)
    end

    it 'copies the Scratch component content' do
      response = described_class.call(lesson:, lesson_params:)
      copied_project = response[:lesson].reload.project

      expect(copied_project.scratch_component.content.to_h)
        .to eq(scratch_content.deep_stringify_keys)
    end

    it 'copies only teacher-owned Scratch assets to the new project owner' do
      create_scratch_asset(
        filename: 'teacher_asset.png',
        project: lesson.project,
        uploaded_user_id: teacher_id,
        body: 'teacher-body'
      )
      create_scratch_asset(
        filename: 'student_asset.png',
        project: lesson.project,
        uploaded_user_id: SecureRandom.uuid,
        body: 'student-body'
      )

      response = described_class.call(lesson:, lesson_params:)
      copied_project = response[:lesson].reload.project
      copied_asset = ScratchAsset.find_by!(
        filename: 'teacher_asset.png',
        project: copied_project,
        uploaded_user_id: copied_teacher_id
      )

      visible_asset = ScratchAsset.find_visible_to_project(
        project: copied_project,
        user: User.new(id: SecureRandom.uuid),
        filename: 'teacher_asset.png'
      )

      expect(copied_asset.file.download).to eq('teacher-body')
      expect(visible_asset).to eq(copied_asset)
      expect(
        ScratchAsset.find_by(filename: 'student_asset.png', project: copied_project)
      ).to be_nil
    end
  end

  context 'when creating a copy fails' do
    let(:lesson_params) { { name: ' ' } }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a lesson' do
      expect { described_class.call(lesson:, lesson_params:) }.not_to change(Lesson, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(lesson:, lesson_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(lesson:, lesson_params:)
      expect(response[:error]).to match(/Error creating copy of lesson/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(lesson:, lesson_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  def create_scratch_asset(filename:, project:, uploaded_user_id:, body:)
    ScratchAsset.create!(filename:, project:, uploaded_user_id:).tap do |asset|
      asset.file.attach(io: StringIO.new(body), filename:, content_type: 'image/png')
    end
  end
end
