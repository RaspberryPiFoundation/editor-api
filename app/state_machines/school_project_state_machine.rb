class SchoolProjectStateMachine
  include Statesman::Machine

  # Define all possible states
  state :unsubmitted, initial: :true
  state :submitted
  state :returned
  state :complete

  # Define transition rules
  transition from: :unsubmitted, to: [:submitted, :complete]
  transition from: :submitted, to: [:unsubmitted, :returned, :complete]
  transition from: :returned, to: [:submitted, :complete]
  transition from: :complete, to: [:unsubmitted]
end
