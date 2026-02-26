# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProject do
  let(:state_machine) { instance_double(SchoolProjectStateMachine) }
  let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
  let(:school_project) { create(:school_project, school:, project: remix) }
  let(:student) { create(:student, school:) }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:teacher_project) { create(:project, school:, user_id: teacher.id, lesson:) }
  let(:remix) { create(:project, school:, user_id: student.id, remixed_from_id: teacher_project.id) }

  before do
    allow(school_project).to receive(:state_machine).and_return(state_machine)
  end

  it { is_expected.to belong_to(:school) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:feedback).dependent(:destroy) }
  it { is_expected.to have_many(:school_project_transitions).dependent(:destroy) }

  describe '#status' do
    it 'defaults to unsubmitted' do
      new_school_project = create(:school_project, school:, project: teacher_project)
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

  describe '#unread_feedback?' do
    it 'returns true if there is unread feedback for the school project' do
      create_list(
        :feedback,
        3,
        school_project: school_project,
        read_at: nil,
        content: 'Unread',
        user_id: teacher.id
      )

      create_list(
        :feedback,
        2,
        school_project: school_project,
        read_at: Time.current,
        content: 'Read',
        user_id: teacher.id
      )

      expect(school_project.unread_feedback?).to be true
    end

    it 'returns false if all feedback is read' do
      create_list(
        :feedback,
        2,
        school_project: school_project,
        read_at: Time.current,
        content: 'Read',
        user_id: teacher.id
      )
      expect(school_project.unread_feedback?).to be false
    end

    it 'returns false when there is no feedback' do
      expect(school_project.unread_feedback?).to be false
    end
  end
end
