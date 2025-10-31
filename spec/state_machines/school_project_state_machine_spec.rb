# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProjectStateMachine do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:project) { create(:project, school: school, user_id: student.id) }
  let(:school_project) { create(:school_project, school: school, project: project) }
  let(:state_machine) { described_class.new(school_project, transition_class: SchoolProjectTransition) }

  describe 'initial state' do
    it 'starts in unsubmitted state' do
      expect(state_machine.current_state).to eq('unsubmitted')
    end
  end

  describe 'transitions' do
    context 'when in unsubmitted state' do
      it 'can transition to submitted' do
        expect(state_machine.can_transition_to?(:submitted)).to be true
      end

      it 'cannot transition to returned' do
        expect(state_machine.can_transition_to?(:returned)).to be false
      end

      it 'can transition to complete' do
        expect(state_machine.can_transition_to?(:complete)).to be true
      end
    end

    context 'when in submitted state' do
      before do
        state_machine.transition_to!(:submitted)
      end

      it 'can transition to unsubmitted' do
        expect(state_machine.can_transition_to?(:unsubmitted)).to be true
      end

      it 'can transition to returned' do
        expect(state_machine.can_transition_to?(:returned)).to be true
      end

      it 'can transition to complete' do
        expect(state_machine.can_transition_to?(:complete)).to be true
      end
    end

    context 'when in returned state' do
      before do
        state_machine.transition_to!(:submitted)
        state_machine.transition_to!(:returned)
      end

      it 'cannot transition to unsubmitted' do
        expect(state_machine.can_transition_to?(:unsubmitted)).to be false
      end

      it 'can transition to submitted' do
        expect(state_machine.can_transition_to?(:submitted)).to be true
      end

      it 'can transition to complete' do
        expect(state_machine.can_transition_to?(:complete)).to be true
      end
    end

    context 'when in complete state' do
      before do
        state_machine.transition_to!(:submitted)
        state_machine.transition_to!(:complete)
      end

      it 'can transition to unsubmitted' do
        expect(state_machine.can_transition_to?(:unsubmitted)).to be true
      end

      it 'cannot transition to submitted' do
        expect(state_machine.can_transition_to?(:submitted)).to be false
      end

      it 'cannot transition to returned' do
        expect(state_machine.can_transition_to?(:returned)).to be false
      end
    end
  end
end
