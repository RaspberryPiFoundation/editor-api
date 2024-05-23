# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::Create, type: :unit do
  let(:teacher_id) { SecureRandom.uuid }

  let(:lesson_params) do
    { name: 'Test Lesson', user_id: teacher_id }
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
    expect(response[:lesson].user_id).to eq(teacher_id)
  end

  context 'when creation fails' do
    let(:lesson_params) { {} }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a lesson' do
      expect { described_class.call(lesson_params:) }.not_to change(Lesson, :count)
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
