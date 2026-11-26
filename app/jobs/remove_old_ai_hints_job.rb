# frozen_string_literal: true

class RemoveOldAiHintsJob < ApplicationJob
  MAX_AGE = 1.day

  queue_as :default

  def perform
    AiHint.where(created_at: ...MAX_AGE.ago).in_batches.delete_all
  end
end
