# frozen_string_literal: true

class SchoolProject < ApplicationRecord
  belongs_to :school
  belongs_to :project
  has_many :feedback, dependent: :destroy
  has_many :school_project_transitions, autosave: false

  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: ::SchoolProjectTransition,
    initial_state: :unsubmitted
  ]

  def status
    state_machine.current_state
  end

  def status=(new_status)
    transition_to!(new_status)
  end

  # Add convenience methods for each state
  def unsubmitted?
    state_machine.in_state?(:unsubmitted)
  end

  def submitted?
    state_machine.in_state?(:submitted)
  end

  def completed?
    state_machine.in_state?(:completed)
  end

  def returned?
    state_machine.in_state?(:returned)
  end

  :delegate :can_transition_to?, :history, :transition_to, :transition_to! to: :state_machine

  private

  def state_machine
    @state_machine ||= SchoolProjectStateMachine.new(self, transition_class: SchoolProjectTransition, initial_transition: true)
  end
end
