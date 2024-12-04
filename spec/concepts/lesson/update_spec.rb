# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::Update, type: :unit do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:student) { create(:student, school:) }
  let(:lesson) { create(:lesson, name: 'Test Lesson', user_id: teacher.id) }
  let!(:student_project) { create(:project, remixed_from_id: lesson.project.id, user_id: student.id) }

  let(:lesson_params) do
    { name: 'New Name' }
  end

  it 'returns a successful operation response' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response.success?).to be(true)
  end

  it 'updates the lesson' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson].name).to eq('New Name')
  end

  it 'updates the project name' do
    described_class.call(lesson:, lesson_params:)
    expect(lesson.project.name).to eq('New Name')
  end

  it 'updates the student project name' do
    described_class.call(lesson:, lesson_params:)
    expect(student_project.reload.name).to eq('New Name')
  end

  it 'returns the lesson in the operation response' do
    response = described_class.call(lesson:, lesson_params:)
    expect(response[:lesson]).to be_a(Lesson)
  end

  context 'when updating fails' do
    let(:lesson_params) { { name: ' ' } }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not update the lesson' do
      response = described_class.call(lesson:, lesson_params:)
      expect(response[:lesson].reload.name).to eq('Test Lesson')
    end

    it 'returns a failed operation response' do
      response = described_class.call(lesson:, lesson_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(lesson:, lesson_params:)
      expect(response[:error]).to match(/Error updating lesson/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(lesson:, lesson_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
