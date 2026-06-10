# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::CreateBatch, type: :unit do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }

  let(:lessons_params) do
    [
      {
        name: 'Test Lesson',
        user_id: teacher.id,
        school_id: school.id,
        origin_identifier: 'test-lesson-identifier-one',
        project_attributes: {
          name: 'Hello world project',
          project_type: Project::Types::PYTHON,
          components: [
            { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
          ]
        }
      },
      {
        name: 'Test Lesson 2',
        user_id: teacher.id,
        school_id: school.id,
        origin_identifier: 'test-lesson-identifier-two',
        project_attributes: {
          name: 'Hello world project',
          project_type: Project::Types::PYTHON,
          components: [
            { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
          ]
        }
      }
    ]
  end

  context 'with a teacher' do
    let(:result) { described_class.call(lessons_params:) }

    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher.id).and_return([teacher])
    end

    it 'returns a successful operation response for the first lesson' do
      expect(result.first.success?).to be(true)
    end

    it 'returns a successful operation response for the second lesson' do
      expect(result.second.success?).to be(true)
    end

    it 'creates multiple lessons' do
      expect { described_class.call(lessons_params:) }.to change(Lesson, :count).by(2)
    end

    it 'does not pass origin_identifier to lesson creation' do
      received_params = []
      allow(Lesson::Create).to receive(:call).and_wrap_original do |method, lesson_params:|
        received_params << lesson_params
        method.call(lesson_params:)
      end

      described_class.call(lessons_params:)

      expect(received_params).to all(satisfy { |params| !params.key?(:origin_identifier) })
    end

    it 'appends the origin_identifier to the first created lesson' do
      expect(result.first[:origin_identifier]).to eq('test-lesson-identifier-one')
    end

    it 'appends the origin_identifier to the second created lesson' do
      expect(result.second[:origin_identifier]).to eq('test-lesson-identifier-two')
    end
  end
end
