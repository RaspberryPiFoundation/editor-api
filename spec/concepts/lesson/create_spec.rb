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

  # Lesson::Create builds the lesson's project as a remix of an
  # already-synced Experience CS project instead of a stub.
  # Assumed signature: described_class.call(lesson_params:, source_project: nil)
  # The controller resolves the locale row (ProjectLoader) and hands over the Project.
  context 'when a source project is given' do
    let(:source_project_en) do
      create(:scratch_project, identifier: 'my-digital-canvas', locale: 'en', user_id: nil,
                               name: 'My digital canvas', origin: Project::Origins::EXPERIENCE_CS)
    end

    let(:source_project_fr) do
      create(:scratch_project, identifier: source_project_en.identifier, locale: 'fr-FR', user_id: nil,
                               name: 'Ma toile numérique', origin: Project::Origins::EXPERIENCE_CS)
    end

    let(:source_project) { source_project_fr }

    let(:lesson_params) do
      {
        name: 'Test Lesson',
        user_id: teacher.id,
        school_id: school.id,
        project_attributes: { name: 'My digital canvas' }
      }
    end

    let(:lesson_project) { result[:lesson].project }

    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher.id).and_return([teacher])
    end

    it 'returns a successful operation response' do
      response = described_class.call(lesson_params:, source_project:)
      expect(response.success?).to be(true)
    end

    it 'creates a lesson' do
      expect { described_class.call(lesson_params:, source_project:) }.to change(Lesson, :count).by(1)
    end

    it 'creates one project for the lesson'

    it 'does not create a second project for the source'

    # remix of the RPF project already in Code Classroom
    it 'sets remixed_from_id to the source project'

    it 'generates a new identifier rather than reusing the source identifier'

    it 'copies the scratch component content from the source project'

    it 'copies the project_type from the source project'

    it 'copies the instructions from the source project'

    # remix of the requested locale row, but locale is null
    it 'copies content from the requested locale row, not the en row'

    it 'sets the lesson project locale to nil'

    # same origin as the remixed project
    it 'inherits origin from the source project'

    it 'leaves origin nil when the source project has no origin'

    # Lesson wiring the plain CreateRemix path does not do
    it 'assigns the lesson id to the project'

    it 'assigns the teacher user id to the project'

    it 'assigns the school id to the project'

    it 'builds a school project for the school'

    it 'sets a remix_origin on the lesson project'

    it 'uses the name from project_attributes when one is given'

    it 'falls back to the source project name when project_attributes has no name'

    it 'does not change the source project'

    it 'does not copy scratch assets (global assets resolve through the lineage)'

    context 'when the lesson project is invalid' do
      # e.g. teacher is not a teacher of the given school_class
      it 'returns a failed operation response'

      it 'does not create a lesson'

      it 'does not create a project'

      it 'sent the exception to Sentry'
    end
  end
end
