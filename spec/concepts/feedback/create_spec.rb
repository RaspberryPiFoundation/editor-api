# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Feedback::Create, type: :unit do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:class_student) { create(:class_student, school_class:, student_id: student.id) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
  let(:teacher_project) { create(:project, user_id: teacher.id, school:, lesson:) }
  let(:student_project) { create(:project, user_id: class_student.student_id, school:, lesson:, parent: teacher_project) }

  let(:feedback_params) do
    {
      content: 'Great job!',
      user_id: teacher.id,
      identifier: student_project.identifier
    }
  end

  context 'when a teacher' do
    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher.id).and_return([teacher])
    end

    it 'returns a successful operation response' do
      response = described_class.call(feedback_params:)
      expect(response.success?).to be(true)
    end

    it 'creates a piece of feedback' do
      expect { described_class.call(feedback_params:) }.to change(Feedback, :count).by(1)
    end

    it 'returns the feedback in the operation response' do
      response = described_class.call(feedback_params:)
      expect(response[:feedback]).to be_a(Feedback)
    end

    it 'assigns the content' do
      response = described_class.call(feedback_params:)
      expect(response[:feedback].content).to eq('Great job!')
    end

    it 'assigns the user_id' do
      response = described_class.call(feedback_params:)
      expect(response[:feedback].user_id).to eq(teacher.id)
    end

    it 'assigns the school_project_id' do
      response = described_class.call(feedback_params:)
      expect(response[:feedback].school_project_id).to eq(student_project.school_project.id)
    end
  end

  context 'when feedback creation fails' do
    let(:rogue_project) { create(:project, user_id: student.id) }
    let(:feedback_params) do
      {
        content: nil,
        user_id: teacher.id,
        identifier: rogue_project.identifier
      }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create feedback' do
      expect { described_class.call(feedback_params:) }.not_to change(Feedback, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(feedback_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(feedback_params:)
      expect(response[:error]).to match(/Error creating feedback/)
    end

    it 'raises school project not found error when no school project' do
      response = described_class.call(feedback_params:)
      expect(response[:error]).to match(/School project must exist/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(feedback_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
