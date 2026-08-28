# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::Create, type: :unit do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }

  let(:lesson_params) do
    {
      name: 'Test Lesson',
      user_id: teacher.id,
      school_id: school.id,
      project_attributes: {
        name: 'Hello world project',
        project_type: Project::Types::PYTHON,
        components: [
          { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
        ]
      }
    }
  end

  context 'when a teacher' do
    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher.id).and_return([teacher])
    end

    it 'returns a successful operation response' do
      response = described_class.call(lesson_params:)
      expect(response.success?).to be(true)
    end

    it 'creates a lesson' do
      expect { described_class.call(lesson_params:) }.to change(Lesson, :count).by(1)
    end

    it 'returns the lesson in the operation response' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson]).to be_a(Lesson)
    end

    it 'assigns the name' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].name).to eq('Test Lesson')
    end

    it 'assigns the user_id' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].user_id).to eq(teacher.id)
    end

    it 'assigns the school_id' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].school_id).to eq(school.id)
    end

    it 'creates a project for the lesson' do
      expect { described_class.call(lesson_params:) }.to change(Project, :count).by(1)
    end

    it 'associates the project to the lesson' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].project).to be_a(Project)
    end

    it 'assigns the user id to the project' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].project.user_id).to eq(response[:lesson].user_id)
    end

    it 'assigns the school id to the project' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].project.school_id).to eq(response[:lesson].school_id)
    end

    it 'assigns the lesson id to the project' do
      response = described_class.call(lesson_params:)
      expect(response[:lesson].project.lesson_id).to eq(response[:lesson].id)
    end
  end

  context 'when lesson creation fails' do
    let(:lesson_params) do
      {
        project_attributes: {
          name: 'Hello world project',
          project_type: Project::Types::PYTHON,
          components: [
            { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
          ]
        }
      }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a lesson' do
      expect { described_class.call(lesson_params:) }.not_to change(Lesson, :count)
    end

    it 'does not create a project' do
      expect { described_class.call(lesson_params:) }.not_to change(Project, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(lesson_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(lesson_params:)
      expect(response[:error]).to include('Error creating lesson')
    end

    it 'sent the exception to Sentry' do
      described_class.call(lesson_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  context 'when project creation fails' do
    let(:lesson_params) do
      {
        name: 'Test Lesson',
        project_attributes: {
          invalid_attribute: 'blah blah blah'
        }
      }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a lesson' do
      expect { described_class.call(lesson_params:) }.not_to change(Lesson, :count)
    end

    it 'does not create a project' do
      expect { described_class.call(lesson_params:) }.not_to change(Project, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(lesson_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(lesson_params:)
      expect(response[:error]).to include('Error creating lesson')
    end

    it 'sent the exception to Sentry' do
      described_class.call(lesson_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  # Lesson::Create builds the lesson's project as a remix of
  # an Experience CS project instead of a stub.
  context 'when a source project is given' do
    let(:english_content) { { 'targets' => [{ 'name' => 'Stage' }], 'monitors' => [], 'extensions' => [], 'meta' => {} } }
    let(:french_content) { { 'targets' => [{ 'name' => 'Scène' }], 'monitors' => [], 'extensions' => [], 'meta' => {} } }

    let(:source_project_en) do
      create(:scratch_project, identifier: 'my-digital-canvas', locale: 'en', user_id: nil,
                               name: 'My digital canvas', origin: Project::Origins::EXPERIENCE_CS,
                               instructions: 'English instructions')
        .tap { |project| project.scratch_component.update!(content: english_content) }
    end

    let(:source_project_fr) do
      create(:scratch_project, identifier: source_project_en.identifier, locale: 'fr-FR', user_id: nil,
                               name: 'Ma toile numérique', origin: Project::Origins::EXPERIENCE_CS,
                               instructions: 'Instructions en français')
        .tap { |project| project.scratch_component.update!(content: french_content) }
    end

    # Eager, so the count matchers below only see what the operation itself creates.
    let!(:source_project) { source_project_fr }

    let(:lesson_params) do
      {
        name: 'Test Lesson',
        user_id: teacher.id,
        school_id: school.id,
        project_attributes: { name: 'My digital canvas' }
      }
    end

    let(:response) { described_class.call(lesson_params:, source_project:) }

    let(:lesson_project) { response[:lesson].project }

    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher.id).and_return([teacher])
    end

    it 'returns a successful operation response' do
      expect(response.success?).to be(true)
    end

    it 'creates a lesson' do
      expect { described_class.call(lesson_params:, source_project:) }.to change(Lesson, :count).by(1)
    end

    it 'creates one project for the lesson' do
      expect { response }.to change(Project, :count).by(1)
    end

    it 'generates a new identifier rather than reusing the source identifier' do
      expect(lesson_project.identifier).not_to eq(source_project.identifier)
    end

    it 'copies the scratch component content from the source project' do
      expect(lesson_project.scratch_component.content).to eq(french_content)
    end

    it 'copies the project_type from the source project' do
      expect(lesson_project.project_type).to eq(Project::Types::CODE_EDITOR_SCRATCH)
    end

    it 'copies the instructions from the source project' do
      expect(lesson_project.instructions).to eq('Instructions en français')
    end

    # remix of the requested locale row, but locale is null
    it 'copies content from the requested locale, not the en locale' do
      expect(lesson_project.scratch_component.content).not_to eq(english_content)
    end

    it 'does not copy the instructions from the en locale' do
      expect(lesson_project.instructions).not_to eq(source_project_en.instructions)
    end

    it 'sets the lesson project locale to nil' do
      expect(lesson_project.locale).to be_nil
    end

    it 'inherits origin from the source project' do
      expect(lesson_project.origin).to eq(source_project.origin)
    end

    it 'assigns the lesson id to the project' do
      expect(lesson_project.lesson_id).to eq(response[:lesson].id)
    end

    it 'assigns the teacher user id to the project' do
      expect(lesson_project.user_id).to eq(teacher.id)
    end

    it 'assigns the school id to the project' do
      expect(lesson_project.school_id).to eq(school.id)
    end

    it 'builds a school project for the school' do
      expect(lesson_project.school_project.school_id).to eq(school.id)
    end

    it 'uses the name from project_attributes when one is given' do
      expect(lesson_project.name).to eq('My digital canvas')
    end

    it 'records the source project id on the lesson project' do
      expect(lesson_project.source_project_id).to eq(source_project.id)
    end

    it 'does not change the source project' do
      expect { response }.not_to(change { source_project.reload.attributes })
    end

    it 'does not copy scratch assets (global assets resolve through the lineage)' do
      create(:scratch_asset, :with_file, project: nil, uploaded_user_id: nil)
      expect { response }.not_to change(ScratchAsset, :count)
    end

    context 'when the source project is itself a remix' do
      let(:source_project_fr) do
        create(:scratch_project, identifier: source_project_en.identifier, locale: 'fr-FR', user_id: nil,
                                 name: 'Ma toile numérique', origin: Project::Origins::EXPERIENCE_CS,
                                 instructions: 'Instructions en français',
                                 remixed_from_id: create(:project).id,
                                 remix_origin: 'example.com')
          .tap { |project| project.scratch_component.update!(content: french_content) }
      end

      it 'does not inherit remixed_from_id from the source project' do
        expect(lesson_project.remixed_from_id).to be_nil
      end

      it 'does not inherit remix_origin from the source project' do
        expect(lesson_project.remix_origin).to be_nil
      end
    end

    context 'when the source project has no origin' do
      let(:source_project) do
        create(:scratch_project, identifier: 'not-backfilled-yet', locale: 'en', user_id: nil, origin: nil)
      end

      it 'leaves the origin nil on the lesson project' do
        expect(lesson_project.origin).to be_nil
      end
    end

    context 'when project_attributes has no name' do
      let(:lesson_params) do
        {
          name: 'Test Lesson',
          user_id: teacher.id,
          school_id: school.id,
          project_attributes: {}
        }
      end

      it 'falls back to the source project name' do
        expect(lesson_project.name).to eq('Ma toile numérique')
      end
    end

    context 'when the lesson project is not a school project' do
      let(:lesson_params) do
        {
          name: 'Test Lesson',
          user_id: teacher.id,
          project_attributes: { name: 'My digital canvas' }
        }
      end

      before do
        allow(Sentry).to receive(:capture_exception)
      end

      it 'returns a failed operation response' do
        expect(response.failure?).to be(true)
      end

      it 'returns the error message in the operation response' do
        expect(response[:error]).to include('Error creating lesson')
      end

      it 'does not create a lesson' do
        expect { response }.not_to change(Lesson, :count)
      end

      it 'does not create a project' do
        expect { response }.not_to change(Project, :count)
      end

      it 'sent the exception to Sentry' do
        response
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end
  end
end
