class SchoolProjectStateMachine
  include Statesman::Machine

  # Define all possible states
  state :unsubmitted, initial: :true
  state :submitted
  state :returned
  state :completed

  # Define transition rules
  transition from: :unsubmitted, to: [:submitted, :completed]
  transition from: :submitted, to: [:unsubmitted, :returned, :completed]
  transition from: :returned, to: [:submitted, :completed]
end