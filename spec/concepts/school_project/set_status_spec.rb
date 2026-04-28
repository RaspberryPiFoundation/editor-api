# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProject::SetStatus, type: :unit do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:project) { create(:project, school:, user_id: student.id) }
  let(:school_project) { create(:school_project, school:, project:) }

  describe '.call' do
    it 'returns a successful operation response' do
      response = described_class.call(school_project:, status: :submitted, user_id: student.id)
      expect(response.success?).to be(true)
    end

    it 'updates the school project status' do
      described_class.call(school_project:, status: :submitted, user_id: student.id)
      expect(school_project.status).to eq('submitted')
    end

    it 'returns the updated school project in the response' do
      response = described_class.call(school_project:, status: :submitted, user_id: student.id)
      expect(response[:school_project]).to be_a(SchoolProject)
    end

    it 'returns an error when transitioning to an invalid status' do
      response = described_class.call(school_project:, status: :returned, user_id: student.id)
      expect(response.success?).to be(false)
      expect(response[:error]).to eq("Cannot transition from '#{school_project.status}' to 'returned'")
    end

    it 'is successful when transitioning to the same status' do
      school_project.transition_status_to!(:submitted, student.id)
      response = described_class.call(school_project:, status: :submitted, user_id: student.id)
      expect(response.success?).to be(true)
      expect(school_project.status).to eq('submitted')
    end

    it 'retries when transition raises a "Statesman::TransitionConflictError" error' do
      call_count = 0
      allow(school_project).to receive(:transition_status_to!).and_wrap_original do |original, *args|
        call_count += 1
        raise Statesman::TransitionConflictError if call_count == 1

        original.call(*args)
      end

      response = described_class.call(school_project:, status: :submitted, user_id: student.id)
      expect(response.success?).to be(true)
      expect(school_project.status).to eq('submitted')
    end

    it 'raises the "Statesman::TransitionConflictError" error after 2 attempts' do
      allow(school_project).to receive(:transition_status_to!).and_raise(Statesman::TransitionConflictError).twice

      expect do
        described_class.call(school_project:, status: :submitted, user_id: student.id)
      end.to raise_error(Statesman::TransitionConflictError)
    end
  end
end
