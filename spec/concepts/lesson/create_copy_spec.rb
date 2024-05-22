# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::CreateCopy, type: :unit do
  let(:teacher_id) { SecureRandom.uuid }

  let!(:lesson) do
    create(:lesson, name: 'Test Lesson', description: 'Description', user_id: teacher_id)
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
end
