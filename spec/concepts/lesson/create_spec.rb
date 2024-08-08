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
        project_type: 'python',
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
          project_type: 'python',
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
      expect(response[:error]).to match(/Error creating lesson/)
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
      expect(response[:error]).to match(/Error creating lesson/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(lesson_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
