# frozen_string_literal: true

class SchoolProject < ApplicationRecord
  belongs_to :school
  belongs_to :project
  has_many :feedback, dependent: :destroy
  has_many :school_project_transitions, autosave: false, dependent: :nullify

  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: ::SchoolProjectTransition,
    initial_state: :unsubmitted
  ]

  def status
    state_machine.current_state
  end

  def transition_status_to!(new_status, user_id)
    state_machine.transition_to!(new_status, metadata: { changed_by: user_id })
  end

  # Add convenience methods for each state
  def unsubmitted?
    state_machine.in_state?(:unsubmitted)
  end

  def submitted?
    state_machine.in_state?(:submitted)
  end

  def complete?
    state_machine.in_state?(:complete)
  end

  def returned?
    state_machine.in_state?(:returned)
  end

  delegate :can_transition_to?, :history, to: :state_machine

  private

  def state_machine
    @state_machine ||= SchoolProjectStateMachine.new(self, transition_class: SchoolProjectTransition)
  end
end
