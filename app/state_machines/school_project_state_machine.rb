# frozen_string_literal: true

class SchoolProjectStateMachine
  include Statesman::Machine

  # Define all possible states
  state :unsubmitted, initial: true
  state :submitted
  state :returned
  state :complete

  # Define transition rules
  transition from: :unsubmitted, to: %i[submitted complete]
  transition from: :submitted, to: %i[unsubmitted returned complete]
  transition from: :returned, to: %i[submitted complete]
  transition from: :complete, to: [:unsubmitted]
end
