# frozen_string_literal: true

class AiHint < ApplicationRecord
  enum :status, { pending: 'pending', completed: 'completed', failed: 'failed' }, default: :pending, validate: true

  validates :user_id, presence: true

  def complete!(hint)
    update!(status: :completed, hint:, input: nil)
  end

  def fail!
    update!(status: :failed, input: nil)
  end
end
