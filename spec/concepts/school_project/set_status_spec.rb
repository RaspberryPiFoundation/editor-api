# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProject::SetStatus, type: :unit do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:project) { create(:project, school:, user_id: student.id) }
  let(:school_project) { create(:school_project, school:, project:) }

  describe '.call' do
    context 'when status transition is successful' do
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
    end

    context 'when status transition fails' do
      before do
        allow(school_project).to receive(:transition_status_to!).and_raise(StandardError, 'Transition failed')
      end

      it 'returns a failed operation response' do
        response = described_class.call(school_project:, status: :submitted, user_id: student.id)
        expect(response.success?).to be(false)
      end

      it 'does not update the school project status' do
        described_class.call(school_project:, status: :submitted, user_id: student.id)
        expect(school_project.status).to eq('unsubmitted')
      end

      it 'includes the error message in the response' do
        response = described_class.call(school_project:, status: :submitted, user_id: student.id)
        expect(response[:error]).to eq('Transition failed')
      end
    end
  end
end
