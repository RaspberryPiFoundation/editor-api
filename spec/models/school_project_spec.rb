# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProject do
  let(:state_machine) { instance_double(SchoolProjectStateMachine) }
  let(:school_project) { create(:school_project, school:, project:) }
  let(:project) { create(:project, school:, user_id: student.id) }
  let(:student) { create(:student, school:) }
  let(:school) { create(:school) }

  before do
    allow(school_project).to receive(:state_machine).and_return(state_machine)
  end

  it { is_expected.to belong_to(:school) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:feedback).dependent(:destroy) }
  it { is_expected.to have_many(:school_project_transitions).dependent(:nullify) }

  describe '#status' do
    it 'defaults to unsubmitted' do
      new_school_project = create(:school_project, school:, project:)
      expect(new_school_project.status).to eq('unsubmitted')
    end

    it 'returns the current state from the state machine' do
      allow(state_machine).to receive(:current_state).and_return('submitted')
      expect(school_project.status).to eq('submitted')
    end
  end

  describe '#transition_status_to!' do
    it 'calls transition_to! on the state machine with the new status and user_id' do
      allow(state_machine).to receive(:transition_to!)
      school_project.transition_status_to!(:submitted, student.id)
      expect(state_machine).to have_received(:transition_to!).with(:submitted, metadata: { changed_by: student.id })
    end
  end

  describe 'convenience methods' do
    it 'checks unsubmitted? state' do
      allow(state_machine).to receive(:in_state?).with(:unsubmitted).and_return(true)
      expect(school_project).to be_unsubmitted
    end

    it 'checks submitted? state' do
      allow(state_machine).to receive(:in_state?).with(:submitted).and_return(true)
      expect(school_project).to be_submitted
    end

    it 'checks returned? state' do
      allow(state_machine).to receive(:in_state?).with(:returned).and_return(true)
      expect(school_project).to be_returned
    end

    it 'checks complete? state' do
      allow(state_machine).to receive(:in_state?).with(:complete).and_return(true)
      expect(school_project).to be_complete
    end
  end

  describe 'delegations' do
    it 'delegates can_transition_to? to state_machine' do
      allow(state_machine).to receive(:can_transition_to?)
      school_project.can_transition_to?(:submitted)
      expect(state_machine).to have_received(:can_transition_to?).with(:submitted)
    end

    it 'delegates history to state_machine' do
      allow(state_machine).to receive(:history)
      school_project.history
      expect(state_machine).to have_received(:history)
    end
  end
end
